import { Injectable } from "@nestjs/common";
import { PaymentStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";

@Injectable()
export class AdminDashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async overview() {
    const now = new Date();
    const todayStart = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
    );
    const weekStart = new Date(todayStart);
    weekStart.setDate(weekStart.getDate() - 7);
    const monthStart = new Date(todayStart);
    monthStart.setMonth(monthStart.getMonth() - 1);

    const [
      totalUsers,
      activeUsers,
      totalVenues,
      totalActivities,
      totalBookings,
      totalRevenue,
      totalRefunds,
      openTickets,
      recentBookings,
    ] = await Promise.all([
      this.prisma.user.count({ where: { status: { not: "DELETED" } } }),
      this.prisma.user.count({ where: { status: "ACTIVE" } }),
      this.prisma.venue.count(),
      this.prisma.activity.count(),
      this.prisma.booking.count(),
      this.prisma.payment.aggregate({
        _sum: { amountPaise: true },
        where: { status: PaymentStatus.CAPTURED },
      }),
      this.prisma.refund.aggregate({
        _sum: { amountPaise: true },
        where: { status: "PROCESSED" },
      }),
      this.prisma.supportTicket.count({
        where: { status: { in: ["OPEN", "IN_PROGRESS"] } },
      }),
      this.prisma.booking.findMany({
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          publicCode: true,
          status: true,
          totalPaise: true,
          createdAt: true,
          user: { select: { name: true, phoneE164: true } },
          slot: {
            select: {
              facility: {
                select: { name: true, venue: { select: { name: true } } },
              },
              startsAt: true,
            },
          },
        },
      }),
    ]);

    return {
      totals: {
        users: totalUsers,
        activeUsers,
        venues: totalVenues,
        activities: totalActivities,
        bookings: totalBookings,
        revenuePaise: (totalRevenue._sum.amountPaise ?? BigInt(0)).toString(),
        refundsPaise: (totalRefunds._sum.amountPaise ?? BigInt(0)).toString(),
        openTickets,
      },
      recentBookings: recentBookings.map((b) => ({
        ...b,
        totalPaise: b.totalPaise.toString(),
        venue: b.slot.facility.venue.name,
        facility: b.slot.facility.name,
        startsAt: b.slot.startsAt,
        userName: b.user.name ?? b.user.phoneE164,
      })),
    };
  }

  async revenueByDay(days: number = 30) {
    const start = new Date();
    start.setDate(start.getDate() - days);
    start.setHours(0, 0, 0, 0);

    const rows = await this.prisma.$queryRawUnsafe<
      Array<{ day: string; revenue: string; count: bigint }>
    >(
      `SELECT DATE(created_at) AS day, SUM(amount_paise) AS revenue, COUNT(*)::int AS count
       FROM payments
       WHERE status = 'CAPTURED' AND created_at >= $1
       GROUP BY DATE(created_at)
       ORDER BY day`,
      start,
    );
    return rows.map((r) => ({
      day: r.day,
      revenuePaise: (r.revenue ? BigInt(r.revenue) : BigInt(0)).toString(),
      count: Number(r.count),
    }));
  }

  async bookingsByDay(days: number = 30) {
    const start = new Date();
    start.setDate(start.getDate() - days);
    start.setHours(0, 0, 0, 0);

    const rows = await this.prisma.$queryRawUnsafe<
      Array<{ day: string; status: string; count: bigint }>
    >(
      `SELECT DATE(created_at) AS day, status, COUNT(*)::int AS count
       FROM bookings
       WHERE created_at >= $1
       GROUP BY DATE(created_at), status
       ORDER BY day`,
      start,
    );
    return rows.map((r) => ({
      day: r.day,
      status: r.status,
      count: Number(r.count),
    }));
  }
}
