import { BadRequestException, Injectable, Logger } from "@nestjs/common";
import { NotificationStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";
import { PushNotificationService } from "../notifications/push-notification.service";

@Injectable()
export class AdminNotificationsService {
  private readonly logger = new Logger(AdminNotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushNotificationService,
  ) {}

  async sendBroadcast(input: {
    title: string;
    body: string;
    userIds?: string[];
    all?: boolean;
  }) {
    const title = input.title.trim();
    const body = input.body.trim();
    if (!title || !body)
      throw new BadRequestException("Title and body are required");
    if (!input.all && (!input.userIds || input.userIds.length === 0))
      throw new BadRequestException("Provide userIds or all=true");

    const userIds = input.all
      ? (
          await this.prisma.user.findMany({
            where: { status: "ACTIVE" },
            select: { id: true },
          })
        ).map((u) => u.id)
      : (
          await this.prisma.user.findMany({
            where: { id: { in: input.userIds }, status: "ACTIVE" },
            select: { id: true },
          })
        ).map((u) => u.id);

    const notifications = await this.prisma.notification.createMany({
      data: userIds.map((userId) => ({
        userId,
        type: "ALERT",
        title,
        body,
        status: NotificationStatus.PENDING,
      })),
    });
    if (notifications.count === 0) return { sent: 0, scheduled: 0 };

    let sent = 0;
    if (this.push.enabled) {
      const devices = await this.prisma.userDevice.findMany({
        where: { userId: { in: userIds } },
        select: { userId: true, token: true },
      });
      for (const device of devices) {
        try {
          await this.push.send({ token: device.token }, { title, body });
          sent++;
        } catch (error) {
          this.logger.error(
            `Push failed for device ${device.token.slice(0, 12)}`,
            error instanceof Error ? error.message : undefined,
          );
        }
      }
    }
    return {
      created: notifications.count,
      pushed: sent,
      scheduled: notifications.count,
    };
  }

  async summary() {
    const [devices, pending] = await Promise.all([
      this.prisma.userDevice.count(),
      this.prisma.notification.count({ where: { status: "PENDING" } }),
      this.prisma.notification.count({ where: { status: "SENT" } }),
      this.prisma.notification.count({ where: { status: "FAILED" } }),
    ]);
    void pending;
    return { devices, sent: 0, scheduled: 0 };
  }

  async getNotificationStats() {
    const [devices, byStatus] = await Promise.all([
      this.prisma.userDevice.count(),
      this.prisma.notification.groupBy({
        by: ["status"],
        _count: { _all: true },
      }),
      this.prisma.notification.count({
        where: { readAt: null, status: "SENT" },
      }),
    ]);
    const counts: Record<string, number> = {
      total: 0,
      sent: 0,
      failed: 0,
      pending: 0,
      unread: 0,
    };
    for (const group of byStatus) counts[group.status] = group._count._all;
    counts.total = Object.values(counts).reduce((a, b) => a + b, 0);
    return { devices, ...counts };
  }
}
