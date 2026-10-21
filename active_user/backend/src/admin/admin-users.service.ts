import { Injectable, NotFoundException } from '@nestjs/common';
import { BookingStatus, PaymentStatus, UserStatus } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AdminUsersService {
  constructor(private readonly prisma: PrismaService) {}

  private formatActivUserId(userId: string) {
    return `ACT-${userId.toUpperCase()}`;
  }

  private parseUserSearchId(search: string) {
    const normalized = search.trim().toLowerCase();
    const withoutPrefix = normalized.startsWith('act-')
      ? normalized.slice(4)
      : normalized;
    const uuidPattern =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
    const compactUuidPattern = /^[0-9a-f]{32}$/;

    if (uuidPattern.test(withoutPrefix)) return withoutPrefix;
    if (!compactUuidPattern.test(withoutPrefix)) return null;

    return [
      withoutPrefix.slice(0, 8),
      withoutPrefix.slice(8, 12),
      withoutPrefix.slice(12, 16),
      withoutPrefix.slice(16, 20),
      withoutPrefix.slice(20),
    ].join('-');
  }

  async list(params: { search?: string; status?: UserStatus; page?: number; limit?: number }) {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 20));
    const where: Record<string, unknown> = {};
    if (params.status) where.status = params.status;
    if (params.search) {
      const s = params.search.trim();
      const searchId = this.parseUserSearchId(s);
      const searchClauses: Record<string, unknown>[] = [
        { phoneE164: { contains: s, mode: 'insensitive' } },
        { name: { contains: s, mode: 'insensitive' } },
        { email: { contains: s, mode: 'insensitive' } },
      ];
      if (searchId) searchClauses.unshift({ id: searchId });
      where.OR = searchClauses;
    }
    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          phoneE164: true,
          name: true,
          email: true,
          status: true,
          isAdmin: true,
          createdAt: true,
          _count: { select: { bookings: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);
    return {
      items: items.map((user) => ({
        ...user,
        activId: this.formatActivUserId(user.id),
      })),
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  async detail(userId: string) {
    const [
      user,
      bookingStatusCounts,
      paymentStatusCounts,
      capturedPayments,
    ] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          phoneE164: true,
          name: true,
          email: true,
          profilePhoto: true,
          status: true,
          isAdmin: true,
          preferences: true,
          deletionRequestedAt: true,
          createdAt: true,
          updatedAt: true,
          partnerUsers: {
            select: {
              role: true,
              partner: { select: { id: true, legalName: true, status: true } },
            },
          },
          _count: {
            select: {
              bookings: true,
              reviews: true,
              supportTickets: true,
              savedVenues: true,
              notifications: true,
            },
          },
          bookings: {
            orderBy: { createdAt: 'desc' },
            take: 10,
            select: {
              id: true,
              publicCode: true,
              status: true,
              totalPaise: true,
              startsAt: true,
              createdAt: true,
            },
          },
        },
      }),
      this.prisma.booking.groupBy({
        by: ['status'],
        where: { userId },
        _count: { _all: true },
      }),
      this.prisma.payment.groupBy({
        by: ['status'],
        where: { booking: { userId } },
        _count: { _all: true },
      }),
      this.prisma.payment.aggregate({
        where: { booking: { userId }, status: PaymentStatus.CAPTURED },
        _sum: { amountPaise: true },
      }),
    ]);
    if (!user) throw new NotFoundException('User not found');

    const bookingCount = (status: BookingStatus) =>
      bookingStatusCounts.find((item) => item.status === status)?._count._all ?? 0;
    const paymentCount = (status: PaymentStatus) =>
      paymentStatusCounts.find((item) => item.status === status)?._count._all ?? 0;
    const partnerRoles = user.partnerUsers.map((partnerUser) => ({
      role: partnerUser.role,
      partner: partnerUser.partner,
    }));
    const role = user.isAdmin ? 'Admin' : partnerRoles.length > 0 ? 'Partner' : 'User';

    return {
      user: {
        id: user.id,
        activId: this.formatActivUserId(user.id),
        name: user.name,
        phoneE164: user.phoneE164,
        email: user.email,
        profilePhoto: user.profilePhoto,
        role,
        isAdmin: user.isAdmin,
        status: user.status,
        preferences: user.preferences,
        deletionRequestedAt: user.deletionRequestedAt,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        partnerRoles,
      },
      stats: {
        totalBookings: user._count.bookings,
        confirmedBookings: bookingCount(BookingStatus.CONFIRMED),
        completedBookings: bookingCount(BookingStatus.COMPLETED),
        cancelledBookings: bookingCount(BookingStatus.CANCELLED),
        savedVenues: user._count.savedVenues,
        reviews: user._count.reviews,
        supportTickets: user._count.supportTickets,
        notifications: user._count.notifications,
        totalPayments: paymentStatusCounts.reduce(
          (total, item) => total + item._count._all,
          0,
        ),
        successfulPayments: paymentCount(PaymentStatus.CAPTURED),
        failedPayments: paymentCount(PaymentStatus.FAILED),
        pendingPayments:
          paymentCount(PaymentStatus.CREATED) +
          paymentCount(PaymentStatus.AUTHORIZED),
        totalSpentPaise: (capturedPayments._sum.amountPaise ?? BigInt(0)).toString(),
      },
      recentBookings: user.bookings.map((booking) => ({
        id: booking.id,
        publicCode: booking.publicCode,
        status: booking.status,
        totalPaise: booking.totalPaise.toString(),
        startsAt: booking.startsAt,
        createdAt: booking.createdAt,
        facilityName: null,
        venueName: null,
        cityCode: null,
      })),
    };
  }

  async updateStatus(userId: string, status: UserStatus, actorId: string) {
    const existing = await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true, status: true } });
    if (!existing) throw new NotFoundException('User not found');
    if (existing.status === status) return { id: userId, status };
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.user.update({ where: { id: userId }, data: { status }, select: { id: true, status: true } });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: 'ADMIN_USER_STATUS_CHANGED',
          entityType: 'USER',
          entityId: userId,
          beforeJson: { status: existing.status },
          afterJson: { status },
        },
      });
      if (status === 'SUSPENDED' || status === 'DELETED') {
        await tx.session.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } });
      }
      return result;
    });
    return updated;
  }
}
