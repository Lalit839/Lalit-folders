import { Injectable, NotFoundException } from "@nestjs/common";
import { TicketStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";

@Injectable()
export class AdminSupportService {
  constructor(private readonly prisma: PrismaService) {}

  async list(params: { status?: TicketStatus; page?: number; limit?: number }) {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 20));
    const where: Record<string, unknown> = {};
    if (params.status) where.status = params.status;
    const [items, total] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          subject: true,
          message: true,
          status: true,
          createdAt: true,
          updatedAt: true,
          user: {
            select: { id: true, name: true, phoneE164: true, email: true },
          },
          booking: { select: { id: true, publicCode: true } },
        },
      }),
      this.prisma.supportTicket.count({ where }),
    ]);
    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  async detail(ticketId: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      select: {
        id: true,
        subject: true,
        message: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        user: {
          select: { id: true, name: true, phoneE164: true, email: true },
        },
        booking: { select: { id: true, publicCode: true, status: true } },
      },
    });
    if (!ticket) throw new NotFoundException("Ticket not found");
    return ticket;
  }

  async updateStatus(ticketId: string, status: TicketStatus, actorId: string) {
    const existing = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      select: { id: true, status: true },
    });
    if (!existing) throw new NotFoundException("Ticket not found");
    if (existing.status === status) return { id: ticketId, status };
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.supportTicket.update({
        where: { id: ticketId },
        data: { status },
        select: { id: true, status: true },
      });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_TICKET_STATUS_CHANGED",
          entityType: "SUPPORT_TICKET",
          entityId: ticketId,
          beforeJson: { status: existing.status },
          afterJson: { status },
        },
      });
      return result;
    });
    return updated;
  }
}
