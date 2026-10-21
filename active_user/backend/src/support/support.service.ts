import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  getNotifications(userId: string) {
    return this.prisma.notification.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 100, select: { id: true, type: true, title: true, body: true, status: true, readAt: true, bookingId: true, createdAt: true, sentAt: true } });
  }

  async markNotificationRead(userId: string, id: string) {
    await this.prisma.notification.updateMany({ where: { id, userId }, data: { readAt: new Date() } });
    return { ok: true };
  }

  async markAllNotificationsRead(userId: string) {
    await this.prisma.notification.updateMany({ where: { userId }, data: { readAt: new Date() } });
    return { ok: true };
  }

  async deleteNotification(userId: string, id: string) {
    const deleted = await this.prisma.notification.deleteMany({ where: { id, userId } });
    if (deleted.count === 0) throw new NotFoundException('Notification not found');
    return { ok: true };
  }

  async createTicket(userId: string, input: { subject: string; message: string; bookingId?: string }) {
    if (input.bookingId) {
      const booking = await this.prisma.booking.findFirst({ where: { id: input.bookingId, userId }, select: { id: true } });
      if (!booking) throw new NotFoundException('Booking not found');
    }
    if (!input.subject.trim() || !input.message.trim()) throw new BadRequestException('Subject and message are required');
    return this.prisma.supportTicket.create({ data: { userId, bookingId: input.bookingId, subject: input.subject.trim(), message: input.message.trim() }, select: { id: true, status: true, subject: true, message: true, bookingId: true, createdAt: true } });
  }
}
