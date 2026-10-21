import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, PaymentStatus, RefundStatus } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AdminBookingsService {
  constructor(private readonly prisma: PrismaService) {}

  private refundableStatuses = new Set<PaymentStatus>([
    PaymentStatus.CAPTURED,
    PaymentStatus.REFUND_PENDING,
    PaymentStatus.REFUNDED,
  ]);

  async list(params: { status?: BookingStatus; search?: string; from?: string; to?: string; page?: number; limit?: number }) {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 20));
    const where: Record<string, unknown> = {};
    if (params.status) where.status = params.status;
    if (params.search) where.publicCode = { contains: params.search.trim(), mode: 'insensitive' };
    if (params.from || params.to) {
      where.createdAt = {};
      if (params.from) (where.createdAt as Record<string, unknown>).gte = new Date(params.from);
      if (params.to) (where.createdAt as Record<string, unknown>).lte = new Date(params.to);
    }
    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          publicCode: true,
          status: true,
          totalPaise: true,
          startsAt: true,
          createdAt: true,
          user: { select: { id: true, name: true, phoneE164: true, email: true } },
          slot: { select: { startsAt: true, endsAt: true, facility: { select: { name: true, venue: { select: { name: true } } } } } },
        },
      }),
      this.prisma.booking.count({ where }),
    ]);
    return { items: items.map((b) => ({ ...b, totalPaise: b.totalPaise.toString() })), page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  async detail(bookingId: string) {
    const [booking, auditEvents] = await Promise.all([
      this.prisma.booking.findUnique({
        where: { id: bookingId },
        select: {
          id: true,
          publicCode: true,
          status: true,
          subtotalPaise: true,
          discountPaise: true,
          totalPaise: true,
          policyVersion: true,
          startsAt: true,
          rescheduleCount: true,
          createdAt: true,
          updatedAt: true,
          user: {
            select: {
              id: true,
              name: true,
              phoneE164: true,
              email: true,
              status: true,
              createdAt: true,
            },
          },
          slot: {
            select: {
              id: true,
              startsAt: true,
              endsAt: true,
              capacity: true,
              bookedQuantity: true,
              pricePaise: true,
              status: true,
              facility: {
                select: {
                  id: true,
                  name: true,
                  capacity: true,
                  activity: { select: { id: true, name: true, sportCode: true, type: true } },
                  venue: {
                    select: {
                      id: true,
                      name: true,
                      cityCode: true,
                      status: true,
                      metadata: true,
                      partnerProfile: {
                        select: {
                          displayName: true,
                          addressLine1: true,
                          addressLine2: true,
                          city: true,
                          state: true,
                          postalCode: true,
                          contactPhoneE164: true,
                          contactEmail: true,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
          attempt: {
            select: {
              id: true,
              quantity: true,
              status: true,
              expiresAt: true,
              quoteSnapshot: true,
              createdAt: true,
              updatedAt: true,
              coupon: {
                select: {
                  id: true,
                  code: true,
                  percentOff: true,
                  amountOffPaise: true,
                  status: true,
                },
              },
            },
          },
          payments: {
            select: {
              id: true,
              provider: true,
              status: true,
              amountPaise: true,
              providerOrderId: true,
              providerPaymentId: true,
              providerEventId: true,
              createdAt: true,
              updatedAt: true,
            },
          },
          refunds: {
            select: {
              id: true,
              amountPaise: true,
              status: true,
              providerRef: true,
              createdAt: true,
              paymentId: true,
            },
          },
          events: {
            orderBy: { createdAt: 'asc' },
            select: {
              id: true,
              fromStatus: true,
              toStatus: true,
              actorId: true,
              metadata: true,
              createdAt: true,
            },
          },
        },
      }),
      this.prisma.auditEvent.findMany({
        where: { entityType: 'BOOKING', entityId: bookingId },
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          actorId: true,
          action: true,
          beforeJson: true,
          afterJson: true,
          createdAt: true,
        },
      }),
    ]);
    if (!booking) throw new NotFoundException('Booking not found');
    return {
      ...booking,
      totalPaise: booking.totalPaise.toString(),
      subtotalPaise: booking.subtotalPaise.toString(),
      discountPaise: booking.discountPaise.toString(),
      slot: {
        ...booking.slot,
        pricePaise: booking.slot.pricePaise.toString(),
      },
      attempt: booking.attempt
        ? {
            ...booking.attempt,
            coupon: booking.attempt.coupon
              ? {
                  ...booking.attempt.coupon,
                  amountOffPaise:
                    booking.attempt.coupon.amountOffPaise?.toString() ?? null,
                }
              : null,
          }
        : null,
      payments: booking.payments.map((p) => ({ ...p, amountPaise: p.amountPaise.toString() })),
      refunds: booking.refunds.map((r) => ({ ...r, amountPaise: r.amountPaise.toString() })),
      auditEvents,
      requestMetadata: null,
    };
  }

  async initiateRefund(
    bookingId: string,
    input: {
      amountPaise?: number;
      paymentId?: string;
      reason?: string;
      status?: RefundStatus;
      providerRef?: string;
    },
    actorId: string,
  ) {
    if (!input.amountPaise || !Number.isSafeInteger(input.amountPaise)) {
      throw new BadRequestException('Refund amount is required');
    }
    if (input.amountPaise <= 0) {
      throw new BadRequestException('Refund amount must be greater than zero');
    }
    const amountPaise = input.amountPaise;
    const status = input.status ?? RefundStatus.PENDING;

    const refund = await this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        select: {
          id: true,
          status: true,
          payments: {
            select: {
              id: true,
              status: true,
              amountPaise: true,
              providerPaymentId: true,
            },
          },
          refunds: {
            select: {
              paymentId: true,
              status: true,
              amountPaise: true,
            },
          },
        },
      });
      if (!booking) throw new NotFoundException('Booking not found');

      const payment = input.paymentId
        ? booking.payments.find((item) => item.id === input.paymentId)
        : booking.payments.find((item) => this.refundableStatuses.has(item.status)) ??
          booking.payments[0];
      if (!payment) {
        throw new BadRequestException('No payment found for this booking');
      }

      const alreadyTracked = booking.refunds
        .filter(
          (item) =>
            item.paymentId === payment.id && item.status !== RefundStatus.FAILED,
        )
        .reduce((total, item) => total + item.amountPaise, BigInt(0));
      const remaining = payment.amountPaise - alreadyTracked;
      if (remaining <= BigInt(0)) {
        throw new ConflictException('Payment is already fully refunded');
      }
      if (BigInt(amountPaise) > remaining) {
        throw new BadRequestException('Refund amount exceeds refundable balance');
      }

      const created = await tx.refund.create({
        data: {
          bookingId: booking.id,
          paymentId: payment.id,
          amountPaise: BigInt(amountPaise),
          status,
          providerRef: input.providerRef ?? null,
        },
        select: {
          id: true,
          bookingId: true,
          paymentId: true,
          amountPaise: true,
          status: true,
          providerRef: true,
          createdAt: true,
        },
      });
      const paymentStatus = this.paymentStatusForRefundStatus(status);
      if (paymentStatus) {
        await tx.payment.update({
          where: { id: payment.id },
          data: { status: paymentStatus },
        });
      }
      await tx.bookingEvent.create({
        data: {
          bookingId: booking.id,
          fromStatus: booking.status,
          toStatus: booking.status,
          actorId,
          metadata: {
            adminRefund: true,
            action: 'CREATED',
            refundId: created.id,
            paymentId: payment.id,
            amountPaise,
            status,
            providerRef: input.providerRef ?? null,
            reason: input.reason ?? null,
          },
        },
      });
      return created;
    });

    return { ...refund, amountPaise: refund.amountPaise.toString() };
  }

  async updateRefund(
    bookingId: string,
    refundId: string,
    input: {
      amountPaise?: number;
      status?: RefundStatus;
      providerRef?: string;
      reason?: string;
    },
    actorId: string,
  ) {
    if (
      input.amountPaise !== undefined &&
      (!Number.isSafeInteger(input.amountPaise) || input.amountPaise <= 0)
    ) {
      throw new BadRequestException('Refund amount must be greater than zero');
    }
    if (
      input.amountPaise === undefined &&
      input.status === undefined &&
      input.providerRef === undefined
    ) {
      throw new BadRequestException('No refund changes provided');
    }

    const refund = await this.prisma.$transaction(async (tx) => {
      const existing = await tx.refund.findFirst({
        where: { id: refundId, bookingId },
        select: {
          id: true,
          bookingId: true,
          paymentId: true,
          amountPaise: true,
          status: true,
          providerRef: true,
          booking: { select: { status: true } },
          payment: { select: { amountPaise: true } },
        },
      });
      if (!existing) throw new NotFoundException('Refund not found');

      const nextAmount =
        input.amountPaise !== undefined
          ? BigInt(input.amountPaise)
          : existing.amountPaise;
      const otherTracked = await tx.refund.aggregate({
        where: {
          bookingId,
          paymentId: existing.paymentId,
          id: { not: refundId },
          status: { not: RefundStatus.FAILED },
        },
        _sum: { amountPaise: true },
      });
      if ((otherTracked._sum.amountPaise ?? BigInt(0)) + nextAmount > existing.payment.amountPaise) {
        throw new BadRequestException('Refund amount exceeds payment amount');
      }

      const updated = await tx.refund.update({
        where: { id: refundId },
        data: {
          ...(input.amountPaise !== undefined ? { amountPaise: nextAmount } : {}),
          ...(input.status !== undefined ? { status: input.status } : {}),
          ...(input.providerRef !== undefined ? { providerRef: input.providerRef || null } : {}),
        },
        select: {
          id: true,
          bookingId: true,
          paymentId: true,
          amountPaise: true,
          status: true,
          providerRef: true,
          createdAt: true,
        },
      });
      const paymentStatus = this.paymentStatusForRefundStatus(updated.status);
      if (paymentStatus) {
        await tx.payment.update({
          where: { id: updated.paymentId },
          data: { status: paymentStatus },
        });
      }
      await tx.bookingEvent.create({
        data: {
          bookingId,
          fromStatus: existing.booking.status,
          toStatus: existing.booking.status,
          actorId,
          metadata: {
            adminRefund: true,
            action: 'UPDATED',
            refundId,
            amountPaise: updated.amountPaise.toString(),
            status: updated.status,
            providerRef: updated.providerRef,
            reason: input.reason ?? null,
          },
        },
      });
      return updated;
    });

    return { ...refund, amountPaise: refund.amountPaise.toString() };
  }

  private paymentStatusForRefundStatus(status: RefundStatus) {
    if (status === RefundStatus.PENDING) return PaymentStatus.REFUND_PENDING;
    if (status === RefundStatus.PROCESSED) return PaymentStatus.REFUNDED;
    if (status === RefundStatus.EXCEPTION_REVIEW)
      return PaymentStatus.EXCEPTION_REVIEW;
    return null;
  }

  async cancel(bookingId: string, actorId: string, reason?: string) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { slot: true, payments: true, attempt: true },
      });
      if (!booking) throw new NotFoundException('Booking not found');
      if (booking.status === BookingStatus.CANCELLED) return { bookingId, status: booking.status };
      if (booking.status !== BookingStatus.CONFIRMED && booking.status !== BookingStatus.PENDING_PAYMENT)
        throw new ConflictException('Booking cannot be cancelled in its current state');

      await tx.$queryRaw`SELECT id FROM slots WHERE id = ${booking.slotId}::uuid FOR UPDATE`;

      if (booking.status === BookingStatus.CONFIRMED) {
        await tx.slot.update({ where: { id: booking.slotId }, data: { bookedQuantity: { decrement: booking.attempt?.quantity ?? 1 } } });
      }

      const updated = await tx.booking.update({
        where: { id: booking.id },
        data: {
          status: BookingStatus.CANCELLED,
          events: { create: { fromStatus: String(booking.status), toStatus: BookingStatus.CANCELLED, actorId, metadata: { reason: reason ?? null, adminCancel: true } } },
        },
        select: { id: true, publicCode: true, status: true },
      });

      const payment = booking.payments.find((p) => p.status === 'CAPTURED');
      let refund: { amountPaise: string; status: string } | null = null;
      if (payment) {
        const configuredRefundPercent = process.env.CANCELLATION_REFUND_PERCENT;
        const refundPercent = configuredRefundPercent === undefined || configuredRefundPercent.trim() === ''
          ? 100
          : Number(configuredRefundPercent);
        const amount = (payment.amountPaise * BigInt(refundPercent)) / BigInt(100);
        const record = await tx.refund.create({ data: { bookingId: booking.id, paymentId: payment.id, amountPaise: amount } });
        await tx.payment.update({ where: { id: payment.id }, data: { status: 'REFUND_PENDING' } });
        refund = { amountPaise: amount.toString(), status: record.status };
      }
      await tx.outboxEvent.create({ data: { type: 'BOOKING_CANCELLED', aggregateId: booking.id, payload: { bookingId: booking.id, userId: booking.userId } } });
      return { booking: updated, refund };
    });
  }
}
