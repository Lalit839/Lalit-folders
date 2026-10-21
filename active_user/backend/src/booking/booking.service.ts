import {
  ConflictException,
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import {
  AttemptStatus,
  BookingStatus,
  CouponStatus,
  Prisma,
} from "@prisma/client";
import { Cron } from "@nestjs/schedule";
import { PrismaService } from "../database/prisma.service";
import { ConfigService } from "@nestjs/config";
import { timePerfStage, timeSyncPerfStage } from "../common/perf-timing";

@Injectable()
export class BookingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config?: ConfigService,
  ) {}

  async getAvailability(slotId: string) {
    const slot = await timePerfStage("booking.slotAvailability.slotDb", () =>
      this.prisma.slot.findUnique({
        where: { id: slotId },
        select: {
          id: true,
          capacity: true,
          bookedQuantity: true,
          startsAt: true,
          endsAt: true,
          status: true,
          pricePaise: true,
        },
      }),
    );
    if (!slot || slot.status !== "AVAILABLE")
      throw new BadRequestException("Slot is not bookable");
    const held = await timePerfStage("booking.slotAvailability.holdsDb", () =>
      this.prisma.bookingAttempt.aggregate({
        where: {
          slotId,
          status: {
            in: [AttemptStatus.HELD, AttemptStatus.PAYMENT_PROCESSING],
          },
          expiresAt: { gt: new Date() },
        },
        _sum: { quantity: true },
      }),
    );
    return timeSyncPerfStage("booking.slotAvailability.serialize", () => {
      const availableQuantity =
        slot.capacity - slot.bookedQuantity - (held._sum.quantity ?? 0);
      if (availableQuantity <= 0)
        throw new ConflictException("Selected slot is no longer available");
      return {
        slotId: slot.id,
        startsAt: slot.startsAt,
        endsAt: slot.endsAt,
        availableQuantity,
        pricePaise: slot.pricePaise.toString(),
        currency: "INR",
      };
    });
  }

  async getVenueAvailability(
    venueId: string,
    date?: string,
    facilityId?: string,
  ) {
    const { day, nextDay } = timeSyncPerfStage(
      "booking.venueAvailability.prepare",
      () => {
        const parsedDay = date ? new Date(`${date}T00:00:00.000Z`) : new Date();
        if (Number.isNaN(parsedDay.valueOf()))
          throw new BadRequestException("Invalid date");
        const parsedNextDay = new Date(parsedDay);
        parsedNextDay.setUTCDate(parsedNextDay.getUTCDate() + 1);
        return { day: parsedDay, nextDay: parsedNextDay };
      },
    );

    const slots = await timePerfStage(
      "booking.venueAvailability.slotsDb",
      () =>
        this.prisma.slot.findMany({
          where: {
            status: "AVAILABLE",
            startsAt: { gte: day, lt: nextDay },
            ...(facilityId ? { facilityId } : {}),
            facility: { venueId, venue: { status: "PUBLISHED" } },
          },
          orderBy: { startsAt: "asc" },
          select: {
            id: true,
            startsAt: true,
            endsAt: true,
            capacity: true,
            bookedQuantity: true,
            pricePaise: true,
            facilityId: true,
          },
        }),
      { hasFacilityFilter: Boolean(facilityId) },
    );

    const activeHolds = await timePerfStage(
      "booking.venueAvailability.holdsDb",
      () =>
        this.prisma.bookingAttempt.groupBy({
          by: ["slotId"],
          where: {
            slotId: { in: slots.map((slot) => slot.id) },
            status: {
              in: [AttemptStatus.HELD, AttemptStatus.PAYMENT_PROCESSING],
            },
            expiresAt: { gt: new Date() },
          },
          _sum: { quantity: true },
        }),
      { slotCount: slots.length },
    );

    return timeSyncPerfStage("booking.venueAvailability.serialize", () => {
      const holds = new Map(
        activeHolds.map((hold) => [hold.slotId, hold._sum.quantity ?? 0]),
      );
      const availableSlots = slots
        .map((slot) => ({
          slot,
          availableQuantity:
            slot.capacity - slot.bookedQuantity - (holds.get(slot.id) ?? 0),
        }))
        .filter((item) => item.availableQuantity > 0);
      return {
        items: availableSlots.map(({ slot, availableQuantity }) => ({
          slotId: slot.id,
          facilityId: slot.facilityId,
          startsAt: slot.startsAt,
          endsAt: slot.endsAt,
          availableQuantity,
          pricePaise: slot.pricePaise.toString(),
          currency: "INR",
        })),
        pagination: { total: availableSlots.length },
      };
    });
  }

  async createAttempt(
    userId: string,
    idempotencyKey: string | undefined,
    slotId: string,
    quantity: number,
  ) {
    if (!idempotencyKey)
      throw new BadRequestException("Idempotency-Key is required");
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.bookingAttempt.findUnique({
        where: { userId_idempotencyKey: { userId, idempotencyKey } },
      });
      if (existing) return this.toAttemptResponse(existing);

      await tx.$queryRaw`SELECT id FROM slots WHERE id = ${slotId}::uuid FOR UPDATE`;
      const slot = await tx.slot.findUnique({ where: { id: slotId } });
      if (!slot || slot.status !== "AVAILABLE" || slot.startsAt <= new Date())
        throw new BadRequestException("Slot is not bookable");
      const active = await tx.bookingAttempt.aggregate({
        where: {
          slotId,
          status: {
            in: [AttemptStatus.HELD, AttemptStatus.PAYMENT_PROCESSING],
          },
          expiresAt: { gt: new Date() },
        },
        _sum: { quantity: true },
      });
      const available =
        slot.capacity - slot.bookedQuantity - (active._sum.quantity ?? 0);
      if (available < quantity)
        throw new ConflictException("Selected slot is no longer available");

      const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
      const attempt = await tx.bookingAttempt.create({
        data: {
          userId,
          slotId,
          quantity,
          expiresAt,
          idempotencyKey,
          quoteSnapshot: {
            subtotal: Number(slot.pricePaise) * quantity,
            discount: 0,
            fees: 0,
            tax: 0,
            total: Number(slot.pricePaise) * quantity,
            currency: "INR",
          },
        },
      });
      return this.toAttemptResponse(attempt);
    });
  }

  async getBookings(userId: string, status?: string, page = 1, limit = 20) {
    const validStatus =
      status && Object.values(BookingStatus).includes(status as BookingStatus)
        ? (status as BookingStatus)
        : undefined;
    const safePage = Math.max(1, Math.floor(page));
    const safeLimit = Math.min(100, Math.max(1, Math.floor(limit)));
    const where = { userId, ...(validStatus ? { status: validStatus } : {}) };
    const bookings = await timePerfStage(
      "bookings.db",
      () =>
        this.prisma.booking.findMany({
          where,
          orderBy: { startsAt: "desc" },
          skip: (safePage - 1) * safeLimit,
          take: safeLimit,
          select: {
            id: true,
            publicCode: true,
            status: true,
            rescheduleCount: true,
            startsAt: true,
            totalPaise: true,
            slot: {
              select: {
                startsAt: true,
                endsAt: true,
                facility: {
                  select: {
                    name: true,
                    venue: { select: { id: true, name: true, cityCode: true } },
                  },
                },
              },
            },
          },
        }),
      { status: validStatus ?? "ALL", page: safePage, limit: safeLimit },
    );
    const total = await timePerfStage("bookings.count", () =>
      this.prisma.booking.count({ where }),
    );
    return timeSyncPerfStage("bookings.serialize", () => ({
      items: bookings.map((booking) => ({
        ...booking,
        totalPaise: booking.totalPaise.toString(),
      })),
      pagination: {
        page: safePage,
        limit: safeLimit,
        total,
        totalPages: Math.ceil(total / safeLimit),
      },
    }));
  }

  async getAttempt(userId: string, attemptId: string) {
    const attempt = await this.prisma.bookingAttempt.findFirst({
      where: { id: attemptId, userId },
      select: {
        id: true,
        status: true,
        expiresAt: true,
        quoteSnapshot: true,
        booking: { select: { id: true, publicCode: true, status: true } },
      },
    });
    if (!attempt) throw new NotFoundException("Booking attempt not found");
    return {
      attemptId: attempt.id,
      status: attempt.status,
      expiresAt: attempt.expiresAt,
      quote: attempt.quoteSnapshot,
      booking: attempt.booking,
    };
  }

  async getBooking(userId: string, bookingId: string) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, userId },
      include: {
        slot: { include: { facility: { include: { venue: true } } } },
        payments: true,
        events: { orderBy: { createdAt: "desc" } },
        attempt: { select: { quantity: true } },
        refunds: true,
      },
    });
    if (!booking) throw new NotFoundException("Booking not found");
    return JSON.parse(
      JSON.stringify(booking, (_key, value: unknown) =>
        typeof value === "bigint" ? value.toString() : value,
      ),
    ) as unknown;
  }

  async getPartnerBookings(userId: string, status?: string) {
    const validStatus =
      status && Object.values(BookingStatus).includes(status as BookingStatus)
        ? (status as BookingStatus)
        : undefined;
    const bookings = await this.prisma.booking.findMany({
      where: {
        ...(validStatus ? { status: validStatus } : {}),
        slot: {
          facility: { venue: { partner: { users: { some: { userId } } } } },
        },
      },
      orderBy: { startsAt: "desc" },
      take: 100,
      select: {
        id: true,
        publicCode: true,
        status: true,
        startsAt: true,
        totalPaise: true,
        user: { select: { id: true, name: true, phoneE164: true } },
        slot: {
          select: {
            startsAt: true,
            endsAt: true,
            facility: {
              select: {
                name: true,
                venue: { select: { id: true, name: true } },
              },
            },
          },
        },
      },
    });
    return bookings.map((booking) => ({
      ...booking,
      totalPaise: booking.totalPaise.toString(),
    }));
  }

  async getPartnerBooking(userId: string, bookingId: string) {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        slot: {
          facility: { venue: { partner: { users: { some: { userId } } } } },
        },
      },
      include: {
        user: { select: { id: true, name: true, phoneE164: true } },
        slot: { include: { facility: { include: { venue: true } } } },
        payments: true,
        events: { orderBy: { createdAt: "desc" } },
      },
    });
    if (!booking) throw new NotFoundException("Booking not found");
    return JSON.parse(
      JSON.stringify(booking, (_key, value: unknown) =>
        typeof value === "bigint" ? value.toString() : value,
      ),
    ) as unknown;
  }

  async getEligibleCoupons(userId: string, attemptId?: string) {
    if (attemptId) {
      const attempt = await this.prisma.bookingAttempt.findFirst({
        where: {
          id: attemptId,
          userId,
          status: AttemptStatus.HELD,
          expiresAt: { gt: new Date() },
        },
        select: { id: true },
      });
      if (!attempt) throw new NotFoundException("Booking attempt not found");
    }
    const coupons = await this.prisma.coupon.findMany({
      where: {
        status: CouponStatus.ACTIVE,
        startsAt: { lte: new Date() },
        endsAt: { gt: new Date() },
      },
      select: {
        code: true,
        percentOff: true,
        amountOffPaise: true,
        endsAt: true,
      },
    });
    return coupons.map((coupon) => ({
      ...coupon,
      amountOffPaise: coupon.amountOffPaise?.toString() ?? null,
    }));
  }

  applyCoupon(
    userId: string,
    attemptId: string,
    key: string | undefined,
    code: string,
  ) {
    return this.updateCoupon(userId, attemptId, key, code);
  }

  removeCoupon(userId: string, attemptId: string, key: string | undefined) {
    return this.updateCoupon(userId, attemptId, key, null);
  }

  async reschedule(
    userId: string,
    bookingId: string,
    idempotencyKey: string | undefined,
    newSlotId: string,
  ) {
    if (!idempotencyKey)
      throw new BadRequestException("Idempotency-Key is required");

    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findFirst({
        where: { id: bookingId, userId },
        include: {
          slot: { include: { facility: { select: { venueId: true } } } },
          attempt: true,
        },
      });
      if (!booking) throw new NotFoundException("Booking not found");
      if (booking.status !== BookingStatus.CONFIRMED)
        throw new ConflictException(
          "Only confirmed bookings can be rescheduled",
        );
      if (booking.rescheduleCount >= 1)
        throw new ConflictException("A booking can be rescheduled only once");
      if (booking.slotId === newSlotId)
        throw new BadRequestException("Replacement slot must be different");
      if (new Date() >= new Date(booking.startsAt.getTime() - 30 * 60 * 1000))
        throw new ConflictException(
          "Rescheduling is closed 30 minutes before the slot",
        );

      await tx.$queryRaw`SELECT id FROM slots WHERE id IN (${booking.slotId}::uuid, ${newSlotId}::uuid) FOR UPDATE`;
      const replacement = await tx.slot.findUnique({
        where: { id: newSlotId },
        include: { facility: { include: { venue: true } } },
      });
      if (
        !replacement ||
        replacement.status !== "AVAILABLE" ||
        replacement.startsAt <= new Date()
      )
        throw new ConflictException("Replacement slot is not available");
      if (replacement.facility.venueId !== booking.slot.facility.venueId)
        throw new ConflictException("Replacement slot must be at same venue");
      if (replacement.pricePaise !== booking.slot.pricePaise)
        throw new ConflictException(
          "Replacement slot must have the same price",
        );

      const quantity = booking.attempt?.quantity ?? 1;
      const held = await tx.bookingAttempt.aggregate({
        where: {
          slotId: newSlotId,
          status: {
            in: [AttemptStatus.HELD, AttemptStatus.PAYMENT_PROCESSING],
          },
          expiresAt: { gt: new Date() },
        },
        _sum: { quantity: true },
      });
      if (
        replacement.capacity -
          replacement.bookedQuantity -
          (held._sum.quantity ?? 0) <
        quantity
      )
        throw new ConflictException("Replacement slot is no longer available");

      await tx.slot.update({
        where: { id: booking.slotId },
        data: { bookedQuantity: { decrement: quantity } },
      });
      await tx.slot.update({
        where: { id: newSlotId },
        data: { bookedQuantity: { increment: quantity } },
      });
      const updated = await tx.booking.update({
        where: { id: booking.id },
        data: {
          slotId: newSlotId,
          startsAt: replacement.startsAt,
          status: BookingStatus.CONFIRMED,
          rescheduleCount: { increment: 1 },
          events: {
            create: {
              fromStatus: BookingStatus.CONFIRMED,
              toStatus: BookingStatus.RESCHEDULED,
              actorId: userId,
              metadata: {
                previousSlotId: booking.slotId,
                replacementSlotId: newSlotId,
                idempotencyKey,
              },
            },
          },
        },
        select: {
          id: true,
          publicCode: true,
          status: true,
          rescheduleCount: true,
          startsAt: true,
          totalPaise: true,
        },
      });
      await tx.outboxEvent.create({
        data: {
          type: "BOOKING_RESCHEDULED",
          aggregateId: booking.id,
          payload: { bookingId: booking.id, userId },
        },
      });
      return { ...updated, totalPaise: updated.totalPaise.toString() };
    });
  }

  async cancel(
    userId: string,
    bookingId: string,
    idempotencyKey: string | undefined,
    reason?: string,
  ) {
    if (!idempotencyKey)
      throw new BadRequestException("Idempotency-Key is required");
    const refundPercentValue = this.config?.get<string>(
      "CANCELLATION_REFUND_PERCENT",
    );
    const refundPercent =
      refundPercentValue === undefined || refundPercentValue.trim() === ""
        ? 100
        : Number(refundPercentValue);
    if (
      refundPercent !== undefined &&
      (!Number.isInteger(refundPercent) ||
        refundPercent < 0 ||
        refundPercent > 100)
    ) {
      throw new BadRequestException("Invalid cancellation refund policy");
    }

    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findFirst({
        where: { id: bookingId, userId },
        include: { slot: true, payments: true, attempt: true },
      });
      if (!booking) throw new NotFoundException("Booking not found");
      if (booking.status === BookingStatus.CANCELLED)
        return { bookingId, status: booking.status };
      if (
        booking.status !== BookingStatus.CONFIRMED &&
        booking.status !== BookingStatus.PENDING_PAYMENT
      ) {
        throw new ConflictException(
          "Booking cannot be cancelled in its current state",
        );
      }
      if (booking.startsAt <= new Date())
        throw new ConflictException("Booking cancellation is closed");
      const payment = booking.payments.find(
        (item) => item.status === "CAPTURED",
      );
      await tx.$queryRaw`SELECT id FROM slots WHERE id = ${booking.slotId}::uuid FOR UPDATE`;
      const quantity = booking.attempt?.quantity ?? 1;
      if (booking.status === BookingStatus.CONFIRMED) {
        await tx.slot.update({
          where: { id: booking.slotId },
          data: { bookedQuantity: { decrement: quantity } },
        });
      }
      const updated = await tx.booking.update({
        where: { id: booking.id },
        data: {
          status: BookingStatus.CANCELLED,
          events: {
            create: {
              fromStatus: String(booking.status),
              toStatus: BookingStatus.CANCELLED,
              actorId: userId,
              metadata: { reason: reason ?? null, idempotencyKey },
            },
          },
          ...(booking.attempt && booking.attempt.status === AttemptStatus.HELD
            ? { attempt: { update: { status: AttemptStatus.RELEASED } } }
            : {}),
        },
        select: { id: true, publicCode: true, status: true },
      });
      let refund: { amountPaise: string; status: string } | null = null;
      if (payment) {
        const amount =
          (payment.amountPaise * BigInt(refundPercent)) / BigInt(100);
        const record = await tx.refund.create({
          data: {
            bookingId: booking.id,
            paymentId: payment.id,
            amountPaise: amount,
          },
        });
        await tx.payment.update({
          where: { id: payment.id },
          data: { status: "REFUND_PENDING" },
        });
        refund = { amountPaise: amount.toString(), status: record.status };
      }
      await tx.outboxEvent.create({
        data: {
          type: "BOOKING_CANCELLED",
          aggregateId: booking.id,
          payload: { bookingId: booking.id, userId },
        },
      });
      return { booking: updated, refund };
    });
  }

  private async updateCoupon(
    userId: string,
    attemptId: string,
    key: string | undefined,
    code: string | null,
  ) {
    if (!key) throw new BadRequestException("Idempotency-Key is required");
    return this.prisma.$transaction(async (tx) => {
      const attempt = await tx.bookingAttempt.findFirst({
        where: {
          id: attemptId,
          userId,
          status: AttemptStatus.HELD,
          expiresAt: { gt: new Date() },
        },
        include: { slot: true },
      });
      if (!attempt) throw new NotFoundException("Booking attempt not found");
      const base = Number(attempt.slot.pricePaise) * attempt.quantity;
      let discount = 0;
      let couponId: string | null = null;
      if (code) {
        const coupon = await tx.coupon.findFirst({
          where: {
            code: code.toUpperCase(),
            status: CouponStatus.ACTIVE,
            startsAt: { lte: new Date() },
            endsAt: { gt: new Date() },
          },
          include: { redemptions: { where: { userId } } },
        });
        if (
          !coupon ||
          (coupon.maxRedemptions !== null &&
            coupon.redemptions.length >= coupon.maxRedemptions) ||
          coupon.redemptions.length >= coupon.perUserLimit ||
          (coupon.percentOff !== null &&
            (coupon.percentOff <= 0 || coupon.percentOff > 100))
        )
          throw new BadRequestException("Coupon is not eligible");
        couponId = coupon.id;
        discount = coupon.percentOff
          ? Math.floor((base * coupon.percentOff) / 100)
          : Math.min(base, Number(coupon.amountOffPaise ?? 0));
      }
      const quote = {
        subtotal: base,
        discount,
        fees: 0,
        tax: 0,
        total: base - discount,
        currency: "INR",
      };
      const updated = await tx.bookingAttempt.update({
        where: { id: attempt.id },
        data: { couponId, quoteSnapshot: quote },
      });
      return this.toAttemptResponse(updated);
    });
  }

  @Cron("*/30 * * * * *")
  async expireBookingAttempts(): Promise<void> {
    const expired = await this.prisma.bookingAttempt.findMany({
      where: {
        status: { in: [AttemptStatus.HELD, AttemptStatus.PAYMENT_PROCESSING] },
        expiresAt: { lte: new Date() },
      },
      select: { id: true },
    });
    if (!expired.length) return;
    await this.prisma.$transaction([
      this.prisma.bookingAttempt.updateMany({
        where: { id: { in: expired.map((item) => item.id) } },
        data: { status: AttemptStatus.EXPIRED },
      }),
      this.prisma.booking.updateMany({
        where: {
          attemptId: { in: expired.map((item) => item.id) },
          status: BookingStatus.PENDING_PAYMENT,
        },
        data: { status: BookingStatus.CANCELLED },
      }),
    ]);
  }

  /** Marks confirmed bookings whose session has ended as COMPLETED.
   *  Runs every 10 min so the user never sees a stale CONFIRMED after the
   *  slot passed (SOW transition gap: CONFIRMED → COMPLETED cron). */
  @Cron("*/10 * * * * *")
  async completeFinishedBookings(): Promise<void> {
    const ended = await this.prisma.booking.findMany({
      where: {
        status: BookingStatus.CONFIRMED,
        slot: { endsAt: { lte: new Date() } },
      },
      select: { id: true },
    });
    if (!ended.length) return;
    await this.prisma.booking.updateMany({
      where: { id: { in: ended.map((item) => item.id) } },
      data: { status: BookingStatus.COMPLETED },
    });
  }

  private toAttemptResponse(attempt: {
    id: string;
    status: AttemptStatus;
    expiresAt: Date;
    quoteSnapshot: Prisma.JsonValue;
  }) {
    return {
      attemptId: attempt.id,
      status: attempt.status,
      expiresAt: attempt.expiresAt,
      quote: attempt.quoteSnapshot,
    };
  }
}
