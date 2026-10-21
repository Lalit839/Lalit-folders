import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  AttemptStatus,
  BookingStatus,
  PaymentStatus,
  RefundStatus,
} from "@prisma/client";
import Razorpay from "razorpay";
import { Cron } from "@nestjs/schedule";
import { createHmac, randomUUID, timingSafeEqual } from "node:crypto";
import { PrismaService } from "../database/prisma.service";
import { timePerfStage, timeSyncPerfStage } from "../common/perf-timing";

type Quote = { subtotal: number; discount: number; total: number };
type RazorpayPaymentEntity = {
  id?: string;
  order_id?: string;
  status?: string;
  captured?: boolean;
  amount?: number;
};

@Injectable()
export class PaymentsService {
  private readonly razorpay?: Razorpay;
  private readonly razorpayKeySecret?: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    const keyId = config.get<string>("RAZORPAY_KEY_ID");
    const keySecret = config.get<string>("RAZORPAY_KEY_SECRET");
    this.razorpayKeySecret = keySecret;
    if (keyId && keySecret)
      this.razorpay = new Razorpay({ key_id: keyId, key_secret: keySecret });
  }

  async createOrder(
    userId: string,
    attemptId: string,
    idempotencyKey: string | undefined,
  ) {
    return timePerfStage("payment.total", async () => {
      timeSyncPerfStage("payment.validation", () => {
        if (!idempotencyKey)
          throw new BadRequestException("Idempotency-Key is required");
        if (!this.razorpay && process.env.DEMO_PAYMENT !== "true")
          throw new ServiceUnavailableException(
            "Payment gateway is not configured",
          );
      });

      if (process.env.DEMO_PAYMENT === "true")
        return this.confirmInDemoMode(userId, attemptId, idempotencyKey!);

      const result = await timePerfStage("payment.transaction", () =>
        this.prisma.$transaction(async (tx) => {
          const attempt = await timePerfStage("payment.bookingDb", () =>
            tx.bookingAttempt.findFirst({
              where: {
                id: attemptId,
                userId,
                status: {
                  in: [AttemptStatus.HELD, AttemptStatus.PAYMENT_PROCESSING],
                },
                expiresAt: { gt: new Date() },
              },
              include: { slot: true, booking: { include: { payments: true } } },
            }),
          );
          if (!attempt)
            throw new ConflictException("Booking attempt is no longer valid");
          const existingPayment = attempt.booking?.payments.find(
            (payment) =>
              payment.provider === "razorpay" && payment.providerOrderId,
          );
          const quote = timeSyncPerfStage("payment.validation", () =>
            this.readQuote(attempt.quoteSnapshot),
          );
          if (existingPayment?.providerOrderId)
            return {
              booking: attempt.booking!,
              payment: existingPayment,
              quote,
              existingOrder: true,
            };
          const booking = attempt.booking
            ? await tx.booking.update({
                where: { id: attempt.booking.id },
                data: { status: BookingStatus.PENDING_PAYMENT },
              })
            : await tx.booking.create({
                data: {
                  publicCode: `ACT-${randomUUID().slice(0, 8).toUpperCase()}`,
                  userId,
                  slotId: attempt.slotId,
                  attemptId: attempt.id,
                  status: BookingStatus.PENDING_PAYMENT,
                  policyVersion: "v1",
                  subtotalPaise: quote.subtotal,
                  discountPaise: quote.discount,
                  totalPaise: quote.total,
                  startsAt: attempt.slot.startsAt,
                },
              });
          const payment =
            attempt.booking?.payments.find(
              (item) => item.provider === "razorpay",
            ) ??
            (await tx.payment.create({
              data: {
                bookingId: booking.id,
                provider: "razorpay",
                amountPaise: quote.total,
              },
            }));
          if (payment.status === PaymentStatus.FAILED)
            await tx.payment.update({
              where: { id: payment.id },
              data: {
                status: PaymentStatus.CREATED,
                providerPaymentId: null,
                providerEventId: null,
              },
            });
          return { booking, payment, quote };
        }),
      );

      try {
        if (result.existingOrder)
          return {
            paymentId: result.payment.id,
            bookingId: result.booking.id,
            orderId: result.payment.providerOrderId,
            amount: result.quote.total,
            currency: "INR",
          };
        const order = await timePerfStage("payment.razorpay", () =>
          this.razorpay!.orders.create({
            amount: result.quote.total,
            currency: "INR",
            receipt: result.booking.publicCode,
            payment_capture: true,
            notes: {
              bookingId: result.booking.id,
              paymentId: result.payment.id,
            },
          }),
        );
        await timePerfStage("payment.dbUpdate", async () => {
          await this.prisma.payment.update({
            where: { id: result.payment.id },
            data: { providerOrderId: order.id },
          });
          await this.prisma.bookingAttempt.update({
            where: { id: attemptId },
            data: { status: AttemptStatus.PAYMENT_PROCESSING },
          });
        });
        return {
          paymentId: result.payment.id,
          bookingId: result.booking.id,
          orderId: order.id,
          amount: result.quote.total,
          currency: "INR",
        };
      } catch {
        await timePerfStage("payment.dbUpdate", () =>
          this.prisma.booking.update({
            where: { id: result.booking.id },
            data: { status: BookingStatus.CANCELLED },
          }),
        );
        throw new ServiceUnavailableException(
          "Payment order could not be created",
        );
      }
    });
  }

  async getStatus(userId: string, paymentId: string) {
    let payment = await this.prisma.payment.findFirst({
      where: { id: paymentId, booking: { userId } },
      select: {
        id: true,
        provider: true,
        status: true,
        providerOrderId: true,
        providerPaymentId: true,
        amountPaise: true,
        bookingId: true,
        updatedAt: true,
      },
    });
    if (!payment) throw new NotFoundException("Payment not found");
    if (
      payment.provider === "razorpay" &&
      payment.status !== PaymentStatus.CAPTURED &&
      payment.providerOrderId &&
      this.razorpay
    ) {
      const synced = await this.syncCapturedRazorpayOrderPayment(
        userId,
        payment.id,
        payment.providerOrderId,
      );
      if (synced) payment = synced;
    }
    return { ...payment, amountPaise: payment.amountPaise.toString() };
  }

  async confirmClientPayment(
    userId: string,
    paymentId: string,
    razorpayPaymentId: string,
    razorpayOrderId: string,
    razorpaySignature: string,
  ) {
    if (!this.razorpay || !this.razorpayKeySecret) {
      throw new ServiceUnavailableException(
        "Payment gateway is not configured",
      );
    }

    const expected = createHmac("sha256", this.razorpayKeySecret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");
    if (
      expected.length !== razorpaySignature.length ||
      !timingSafeEqual(Buffer.from(expected), Buffer.from(razorpaySignature))
    ) {
      throw new UnauthorizedException("Invalid payment signature");
    }

    const existingPayment = await this.prisma.payment.findFirst({
      where: { id: paymentId, booking: { userId } },
      include: { booking: true },
    });
    if (!existingPayment) throw new NotFoundException("Payment not found");
    if (existingPayment.providerOrderId !== razorpayOrderId) {
      throw new BadRequestException("Payment order does not match");
    }

    const gatewayPayment = (await this.razorpay.payments.fetch(
      razorpayPaymentId,
    )) as RazorpayPaymentEntity;
    if (
      gatewayPayment.order_id !== razorpayOrderId ||
      gatewayPayment.id !== razorpayPaymentId
    ) {
      throw new BadRequestException("Payment gateway response does not match");
    }
    if (
      gatewayPayment.status !== "captured" &&
      gatewayPayment.captured !== true
    ) {
      throw new ConflictException("Payment is not captured yet");
    }

    const updated = await this.settleCapturedRazorpayPayment(
      userId,
      paymentId,
      gatewayPayment,
    );

    return {
      id: updated.id,
      status: updated.status,
      providerOrderId: updated.providerOrderId,
      providerPaymentId: updated.providerPaymentId,
      amountPaise: updated.amountPaise.toString(),
      bookingId: updated.bookingId,
      updatedAt: updated.updatedAt,
    };
  }

  private async syncCapturedRazorpayOrderPayment(
    userId: string,
    paymentId: string,
    razorpayOrderId: string,
  ) {
    try {
      const response = (await this.razorpay?.orders.fetchPayments(
        razorpayOrderId,
      )) as { items?: RazorpayPaymentEntity[] } | undefined;
      const captured = response?.items?.find(
        (item) => item.status === "captured" || item.captured === true,
      );
      if (!captured?.id) return null;
      return await this.settleCapturedRazorpayPayment(
        userId,
        paymentId,
        captured,
      );
    } catch {
      return null;
    }
  }

  private async settleCapturedRazorpayPayment(
    userId: string,
    paymentId: string,
    gatewayPayment: RazorpayPaymentEntity,
    providerEventId?: string,
  ) {
    if (!gatewayPayment.id || !gatewayPayment.order_id) {
      throw new BadRequestException("Payment gateway response is incomplete");
    }
    if (
      gatewayPayment.status !== "captured" &&
      gatewayPayment.captured !== true
    ) {
      throw new ConflictException("Payment is not captured yet");
    }

    return await this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.findFirst({
        where: { id: paymentId, booking: { userId } },
        include: { booking: true },
      });
      if (!payment) throw new NotFoundException("Payment not found");
      if (payment.status === PaymentStatus.CAPTURED) return payment;
      if (payment.providerOrderId !== gatewayPayment.order_id) {
        throw new BadRequestException("Payment order does not match");
      }

      await tx.$queryRaw`SELECT id FROM slots WHERE id = ${payment.booking.slotId}::uuid FOR UPDATE`;
      const attempt = payment.booking.attemptId
        ? await tx.bookingAttempt.findUnique({
            where: { id: payment.booking.attemptId },
          })
        : null;
      if (gatewayPayment.amount !== Number(payment.amountPaise)) {
        await tx.payment.update({
          where: { id: payment.id },
          data: {
            providerPaymentId: gatewayPayment.id,
            ...(providerEventId ? { providerEventId } : {}),
            status: PaymentStatus.EXCEPTION_REVIEW,
          },
        });
        await tx.outboxEvent.create({
          data: {
            type: "PAYMENT_EXCEPTION_REVIEW",
            aggregateId: payment.bookingId,
            payload: {
              bookingId: payment.bookingId,
              paymentId: payment.id,
              reason: "AMOUNT_MISMATCH",
            },
          },
        });
        throw new ConflictException("Payment amount mismatch");
      }

      await tx.$queryRaw`SELECT id FROM slots WHERE id = ${payment.booking.slotId}::uuid FOR UPDATE`;
      const slotState = await tx.slot.findUnique({
        where: { id: payment.booking.slotId },
        select: { capacity: true, bookedQuantity: true },
      });
      const quantity = attempt?.quantity ?? 1;
      const shouldReserveSlot =
        payment.booking.status !== BookingStatus.CONFIRMED &&
        payment.booking.status !== BookingStatus.COMPLETED;
      if (
        shouldReserveSlot &&
        (!slotState || slotState.bookedQuantity + quantity > slotState.capacity)
      ) {
        throw new ConflictException(
          "Slot capacity changed during payment confirmation",
        );
      }

      const confirmedPayment = await tx.payment.update({
        where: { id: payment.id },
        data: {
          providerPaymentId: gatewayPayment.id,
          ...(providerEventId ? { providerEventId } : {}),
          status: PaymentStatus.CAPTURED,
        },
      });
      await tx.booking.update({
        where: { id: payment.bookingId },
        data: { status: BookingStatus.CONFIRMED },
      });
      if (attempt) {
        await tx.bookingAttempt.update({
          where: { id: attempt.id },
          data: { status: AttemptStatus.CONSUMED },
        });
      }
      if (shouldReserveSlot) {
        await tx.slot.update({
          where: { id: payment.booking.slotId },
          data: { bookedQuantity: { increment: quantity } },
        });
      }
      if (attempt?.couponId) {
        await tx.couponRedemption.create({
          data: {
            couponId: attempt.couponId,
            userId,
            bookingId: payment.bookingId,
          },
        });
      }
      await tx.outboxEvent.create({
        data: {
          type: "BOOKING_CONFIRMED",
          aggregateId: payment.bookingId,
          payload: { bookingId: payment.bookingId, userId },
        },
      });
      return confirmedPayment;
    });
  }

  async handleWebhook(signature: string | undefined, rawBody: Buffer) {
    const secret = this.config.get<string>("RAZORPAY_WEBHOOK_SECRET");
    if (!signature || !secret)
      throw new UnauthorizedException("Invalid webhook");
    const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
    if (
      expected.length !== signature.length ||
      !timingSafeEqual(Buffer.from(expected), Buffer.from(signature))
    )
      throw new UnauthorizedException("Invalid webhook");
    let event: {
      id?: string;
      event?: string;
      payload?: {
        payment?: {
          entity?: { id?: string; order_id?: string; amount?: number };
        };
      };
    };
    try {
      event = JSON.parse(rawBody.toString()) as typeof event;
    } catch {
      throw new BadRequestException("Invalid webhook payload");
    }
    const entity = event.payload?.payment?.entity;
    if (!entity?.order_id) return { received: true };
    if (event.event !== "payment.captured" && event.event !== "payment.failed")
      return { received: true };

    if (event.event === "payment.captured") {
      if (
        event.id &&
        (await this.prisma.payment.findFirst({
          where: { providerEventId: event.id },
          select: { id: true },
        }))
      )
        return { received: true };
      const payment = await this.prisma.payment.findFirst({
        where: { provider: "razorpay", providerOrderId: entity.order_id },
        include: { booking: true },
      });
      if (!payment || payment.status === PaymentStatus.CAPTURED)
        return { received: true };
      await this.settleCapturedRazorpayPayment(
        payment.booking.userId,
        payment.id,
        {
          id: entity.id,
          order_id: entity.order_id,
          amount: entity.amount,
          status: "captured",
          captured: true,
        },
        event.id,
      );
      return { received: true };
    }

    await this.prisma.$transaction(async (tx) => {
      if (
        event.id &&
        (await tx.payment.findFirst({
          where: { providerEventId: event.id },
          select: { id: true },
        }))
      )
        return;
      const payment = await tx.payment.findFirst({
        where: { provider: "razorpay", providerOrderId: entity.order_id },
        include: { booking: true },
      });
      if (!payment || payment.status === PaymentStatus.CAPTURED) return;
      await tx.payment.update({
        where: { id: payment.id },
        data: {
          providerPaymentId: entity.id,
          providerEventId: event.id,
          status: PaymentStatus.FAILED,
        },
      });
      await tx.booking.update({
        where: { id: payment.bookingId },
        data: { status: BookingStatus.CANCELLED },
      });
      await tx.outboxEvent.create({
        data: {
          type: "PAYMENT_FAILED",
          aggregateId: payment.bookingId,
          payload: {
            bookingId: payment.bookingId,
            userId: payment.booking.userId,
          },
        },
      });
    });
    return { received: true };
  }

  @Cron("*/30 * * * * *")
  async syncPendingRazorpayPayments(): Promise<void> {
    if (!this.razorpay) return;
    const payments = await this.prisma.payment.findMany({
      where: {
        provider: "razorpay",
        status: {
          in: [
            PaymentStatus.CREATED,
            PaymentStatus.AUTHORIZED,
            PaymentStatus.EXCEPTION_REVIEW,
          ],
        },
        providerOrderId: { not: null },
      },
      include: { booking: { select: { userId: true } } },
      orderBy: { updatedAt: "asc" },
      take: 20,
    });
    for (const payment of payments) {
      if (!payment.providerOrderId) continue;
      try {
        await this.syncCapturedRazorpayOrderPayment(
          payment.booking.userId,
          payment.id,
          payment.providerOrderId,
        );
      } catch {
        // Keep the payment pending; the next run or webhook can reconcile it.
      }
    }
  }

  private async confirmInDemoMode(
    userId: string,
    attemptId: string,
    idempotencyKey: string,
  ) {
    const result = await this.prisma.$transaction(async (tx) => {
      const attempt = await tx.bookingAttempt.findFirst({
        where: {
          id: attemptId,
          userId,
          status: AttemptStatus.HELD,
          expiresAt: { gt: new Date() },
        },
        include: { slot: true, booking: { include: { payments: true } } },
      });
      if (!attempt)
        throw new ConflictException("Booking attempt is no longer valid");

      const captured = attempt.booking?.payments.find(
        (payment) =>
          payment.provider === "demo" &&
          payment.status === PaymentStatus.CAPTURED,
      );
      if (captured)
        return {
          booking: attempt.booking!,
          payment: captured,
          quote: this.readQuote(attempt.quoteSnapshot),
        };

      const quote = this.readQuote(attempt.quoteSnapshot);
      const booking = attempt.booking
        ? await tx.booking.update({
            where: { id: attempt.booking.id },
            data: { status: BookingStatus.PENDING_PAYMENT },
          })
        : await tx.booking.create({
            data: {
              publicCode: `ACT-${randomUUID().slice(0, 8).toUpperCase()}`,
              userId,
              slotId: attempt.slotId,
              attemptId: attempt.id,
              status: BookingStatus.PENDING_PAYMENT,
              policyVersion: "v1",
              subtotalPaise: quote.subtotal,
              discountPaise: quote.discount,
              totalPaise: quote.total,
              startsAt: attempt.slot.startsAt,
            },
          });

      const orderId = `demo_${idempotencyKey || randomUUID().slice(0, 12)}`;
      const existing = attempt.booking?.payments.find(
        (payment) => payment.provider === "demo",
      );
      const payment = existing
        ? await tx.payment.update({
            where: { id: existing.id },
            data: {
              status: PaymentStatus.CAPTURED,
              providerOrderId: orderId,
            },
          })
        : await tx.payment.create({
            data: {
              bookingId: booking.id,
              provider: "demo",
              amountPaise: quote.total,
              status: PaymentStatus.CAPTURED,
              providerOrderId: orderId,
            },
          });

      await tx.booking.update({
        where: { id: booking.id },
        data: { status: BookingStatus.CONFIRMED },
      });
      await tx.bookingAttempt.update({
        where: { id: attempt.id },
        data: { status: AttemptStatus.CONSUMED },
      });
      await tx.$queryRaw`SELECT id FROM slots WHERE id = ${attempt.slotId}::uuid FOR UPDATE`;
      const slotState = await tx.slot.findUnique({
        where: { id: attempt.slotId },
        select: { capacity: true, bookedQuantity: true },
      });
      if (
        !slotState ||
        slotState.bookedQuantity + attempt.quantity > slotState.capacity
      )
        throw new ConflictException(
          "Slot capacity changed during payment confirmation",
        );
      await tx.slot.update({
        where: { id: attempt.slotId },
        data: { bookedQuantity: { increment: attempt.quantity } },
      });
      if (attempt.couponId)
        await tx.couponRedemption.create({
          data: {
            couponId: attempt.couponId,
            userId,
            bookingId: booking.id,
          },
        });
      await tx.outboxEvent.create({
        data: {
          type: "BOOKING_CONFIRMED",
          aggregateId: booking.id,
          payload: { bookingId: booking.id, userId },
        },
      });
      return { booking, payment, quote };
    });

    return {
      paymentId: result.payment.id,
      bookingId: result.booking.id,
      orderId: result.payment.providerOrderId,
      amount: result.quote.total,
      currency: "INR",
      demo: true,
    };
  }

  @Cron("*/30 * * * * *")
  async processPendingRefunds(): Promise<void> {
    const refunds = await this.prisma.refund.findMany({
      where: { status: RefundStatus.PENDING },
      include: { payment: true },
      orderBy: { createdAt: "asc" },
      take: 20,
    });
    for (const refund of refunds) {
      if (this.razorpay && refund.payment.providerPaymentId) {
        try {
          const result = await this.razorpay.payments.refund(
            refund.payment.providerPaymentId,
            {
              amount: Number(refund.amountPaise),
              notes: { bookingId: refund.bookingId, refundId: refund.id },
            },
          );
          await this.prisma.$transaction([
            this.prisma.refund.update({
              where: { id: refund.id },
              data: { status: RefundStatus.PROCESSED, providerRef: result.id },
            }),
            this.prisma.payment.update({
              where: { id: refund.paymentId },
              data: { status: PaymentStatus.REFUNDED },
            }),
          ]);
        } catch (error) {
          await this.prisma.refund.update({
            where: { id: refund.id },
            data: {
              status: RefundStatus.FAILED,
              providerRef:
                error instanceof Error
                  ? error.message.slice(0, 255)
                  : "Refund failed",
            },
          });
        }
      } else {
        // Demo mode (no Razorpay configured) or a payment without a provider id:
        // settle the refund immediately so cancelled bookings reflect the refund.
        await this.prisma.$transaction([
          this.prisma.refund.update({
            where: { id: refund.id },
            data: { status: RefundStatus.PROCESSED, providerRef: "demo" },
          }),
          this.prisma.payment.update({
            where: { id: refund.paymentId },
            data: { status: PaymentStatus.REFUNDED },
          }),
        ]);
      }
    }
  }

  private readQuote(value: unknown): Quote {
    if (
      !value ||
      typeof value !== "object" ||
      !("total" in value) ||
      typeof value.total !== "number" ||
      !Number.isSafeInteger(value.total) ||
      value.total <= 0
    )
      throw new BadRequestException("Invalid booking quote");
    const quote = value as {
      subtotal?: number;
      discount?: number;
      total: number;
    };
    return {
      subtotal: quote.subtotal ?? quote.total,
      discount: quote.discount ?? 0,
      total: quote.total,
    };
  }
}
