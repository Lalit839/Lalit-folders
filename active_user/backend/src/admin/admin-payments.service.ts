import { Injectable } from '@nestjs/common';
import { PaymentStatus } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AdminPaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  async listPayments(params: { status?: PaymentStatus; from?: string; to?: string; page?: number; limit?: number }) {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 20));
    const where: Record<string, unknown> = {};
    if (params.status) where.status = params.status;
    if (params.from || params.to) {
      where.createdAt = {};
      if (params.from) (where.createdAt as Record<string, unknown>).gte = new Date(params.from);
      if (params.to) (where.createdAt as Record<string, unknown>).lte = new Date(params.to);
    }
    const [items, total] = await Promise.all([
      this.prisma.payment.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          provider: true,
          status: true,
          amountPaise: true,
          providerOrderId: true,
          providerPaymentId: true,
          createdAt: true,
          booking: { select: { id: true, publicCode: true, user: { select: { name: true, phoneE164: true } } } },
        },
      }),
      this.prisma.payment.count({ where }),
    ]);
    return { items: items.map((p) => ({ ...p, amountPaise: p.amountPaise.toString() })), page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  async listRefunds(params: { status?: string; page?: number; limit?: number }) {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 20));
    const where: Record<string, unknown> = {};
    if (params.status) where.status = params.status;
    const [items, total] = await Promise.all([
      this.prisma.refund.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          amountPaise: true,
          status: true,
          providerRef: true,
          createdAt: true,
          booking: {
            select: { id: true, publicCode: true, user: { select: { name: true, phoneE164: true } } },
          },
          payment: { select: { id: true, provider: true, providerPaymentId: true } },
        },
      }),
      this.prisma.refund.count({ where }),
    ]);
    return { items: items.map((r) => ({ ...r, amountPaise: r.amountPaise.toString() })), page, limit, total, totalPages: Math.ceil(total / limit) };
  }
}