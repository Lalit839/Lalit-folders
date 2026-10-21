import { Injectable, Logger } from "@nestjs/common";
import { Cron } from "@nestjs/schedule";
import { NotificationStatus, OutboxStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";
import { PushNotificationService } from "../notifications/push-notification.service";

const HANDLED_EVENTS = new Set([
  "BOOKING_CONFIRMED",
  "BOOKING_CANCELLED",
  "BOOKING_RESCHEDULED",
  "PAYMENT_FAILED",
  "PAYMENT_EXCEPTION_REVIEW",
]);

function messageFor(type: string): { title: string; body: string } {
  switch (type) {
    case "BOOKING_CONFIRMED":
      return {
        title: "Booking confirmed",
        body: "Your ACTIV booking is confirmed.",
      };
    case "BOOKING_CANCELLED":
      return {
        title: "Booking cancelled",
        body: "Your ACTIV booking has been cancelled.",
      };
    case "BOOKING_RESCHEDULED":
      return {
        title: "Booking rescheduled",
        body: "Your ACTIV booking has been rescheduled.",
      };
    case "PAYMENT_FAILED":
      return {
        title: "Payment update",
        body: "Your payment could not be completed.",
      };
    case "PAYMENT_EXCEPTION_REVIEW":
      return {
        title: "Payment update",
        body: "Your payment requires support review.",
      };
    default:
      return {
        title: "ACTIV update",
        body: "You have a new update from ACTIV.",
      };
  }
}

@Injectable()
export class OutboxService {
  private readonly logger = new Logger(OutboxService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly push: PushNotificationService,
  ) {}

  @Cron("*/10 * * * * *")
  async dispatchPending(): Promise<void> {
    const events = await this.prisma.outboxEvent.findMany({
      where: { status: OutboxStatus.PENDING },
      orderBy: { createdAt: "asc" },
      take: 50,
    });
    for (const event of events) {
      try {
        if (!HANDLED_EVENTS.has(event.type)) {
          await this.prisma.outboxEvent.update({
            where: { id: event.id },
            data: {
              status: OutboxStatus.FAILED,
              attempts: { increment: 1 },
              lastError: "No handler registered for event type",
            },
          });
          continue;
        }
        const payload = event.payload as {
          bookingId?: string;
          userId?: string;
        };
        let createdId: string | undefined;
        if (payload.userId) {
          const message = messageFor(event.type);
          const created = await this.prisma.$transaction(async (tx) => {
            const claimed = await tx.outboxEvent.updateMany({
              where: { id: event.id, status: OutboxStatus.PENDING },
              data: {
                status: OutboxStatus.PUBLISHED,
                attempts: { increment: 1 },
                publishedAt: new Date(),
              },
            });
            if (!claimed.count) return undefined;
            const notification = await tx.notification.create({
              data: {
                userId: payload.userId!,
                bookingId: payload.bookingId,
                type: event.type,
                ...message,
                status: NotificationStatus.SENT,
                sentAt: new Date(),
              },
              select: { id: true },
            });
            return notification.id;
          });
          createdId = created;
          await this.dispatchPush(payload.userId, message);
        } else {
          await this.prisma.outboxEvent.updateMany({
            where: { id: event.id, status: OutboxStatus.PENDING },
            data: {
              status: OutboxStatus.PUBLISHED,
              attempts: { increment: 1 },
              publishedAt: new Date(),
            },
          });
        }
        void createdId;
      } catch (error) {
        this.logger.error(
          `Outbox event ${event.id} failed`,
          error instanceof Error ? error.stack : undefined,
        );
        const attempts = event.attempts + 1;
        await this.prisma.outboxEvent.updateMany({
          where: { id: event.id, status: OutboxStatus.PENDING },
          data: {
            attempts,
            status: attempts >= 5 ? OutboxStatus.FAILED : OutboxStatus.PENDING,
            lastError: error instanceof Error ? error.message : "Unknown error",
          },
        });
      }
    }
  }

  private async dispatchPush(
    userId: string,
    message: { title: string; body: string },
  ): Promise<void> {
    try {
      if (!this.push.enabled) return;
      const devices = await this.prisma.userDevice.findMany({
        where: { userId },
        select: { token: true },
      });
      if (!devices.length) return;
      for (const device of devices) {
        try {
          await this.push.send(device, message);
        } catch (error) {
          const messageText =
            error instanceof Error ? error.message : "Push delivery failed";
          if (messageText.includes("UNREGISTERED")) {
            await this.prisma.userDevice
              .deleteMany({
                where: { userId, token: device.token },
              })
              .catch(() => undefined);
          }
          this.logger.warn(
            `Push to device ${device.token.slice(0, 12)}… for user ${userId} failed`,
            messageText,
          );
        }
      }
    } catch (error) {
      this.logger.error(
        `Push dispatch for user ${userId} failed`,
        error instanceof Error ? error.message : undefined,
      );
    }
  }
}
