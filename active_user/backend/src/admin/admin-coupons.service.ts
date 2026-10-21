import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CouponStatus } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AdminCouponsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(params: { status?: CouponStatus; page?: number; limit?: number }) {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 20));
    const where: Record<string, unknown> = {};
    if (params.status) where.status = params.status;
    const [items, total] = await Promise.all([
      this.prisma.coupon.findMany({
        where,
        orderBy: { id: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          code: true,
          status: true,
          percentOff: true,
          amountOffPaise: true,
          startsAt: true,
          endsAt: true,
          maxRedemptions: true,
          perUserLimit: true,
          _count: { select: { redemptions: true } },
        },
      }),
      this.prisma.coupon.count({ where }),
    ]);
    return { items: items.map((c) => ({ ...c, amountOffPaise: c.amountOffPaise?.toString() ?? null })), page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  async create(input: {
    code: string;
    percentOff?: number;
    amountOffPaise?: number;
    startsAt: string;
    endsAt: string;
    maxRedemptions?: number;
    perUserLimit?: number;
  }, actorId: string) {
    const code = input.code.trim().toUpperCase();
    if (!code) throw new BadRequestException('Coupon code is required');
    const existing = await this.prisma.coupon.findUnique({ where: { code } });
    if (existing) throw new BadRequestException('Coupon code already exists');
    if (input.percentOff && input.amountOffPaise) throw new BadRequestException('Provide either percentOff or amountOff, not both');
    if (!input.percentOff && !input.amountOffPaise) throw new BadRequestException('Provide either percentOff or amountOff');
    if (input.percentOff && (input.percentOff <= 0 || input.percentOff > 100)) throw new BadRequestException('percentOff must be 1-100');
    if (input.amountOffPaise && input.amountOffPaise <= 0) throw new BadRequestException('amountOff must be positive');

    const created = await this.prisma.$transaction(async (tx) => {
      const result = await tx.coupon.create({
        data: {
          code,
          percentOff: input.percentOff,
          amountOffPaise: input.amountOffPaise ? BigInt(input.amountOffPaise) : null,
          startsAt: new Date(input.startsAt),
          endsAt: new Date(input.endsAt),
          maxRedemptions: input.maxRedemptions,
          perUserLimit: input.perUserLimit ?? 1,
        },
      });
      await tx.auditEvent.create({ data: { actorId, action: 'ADMIN_COUPON_CREATED', entityType: 'COUPON', entityId: result.id, afterJson: { code: result.code } } });
      return result;
    });
    return created;
  }

  async update(couponId: string, input: Record<string, unknown>, actorId: string) {
    const existing = await this.prisma.coupon.findUnique({ where: { id: couponId } });
    if (!existing) throw new NotFoundException('Coupon not found');
    const data = { ...input } as Record<string, unknown>;
    if (input.startsAt !== undefined) data.startsAt = new Date(input.startsAt as string);
    if (input.endsAt !== undefined) data.endsAt = new Date(input.endsAt as string);
    if (input.amountOffPaise !== undefined) data.amountOffPaise = data.amountOffPaise === null ? null : BigInt(data.amountOffPaise as number);
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.coupon.update({ where: { id: couponId }, data });
      await tx.auditEvent.create({ data: { actorId, action: 'ADMIN_COUPON_UPDATED', entityType: 'COUPON', entityId: couponId, beforeJson: { code: existing.code }, afterJson: { code: result.code } } });
      return result;
    });
    return updated;
  }

  async setStatus(couponId: string, status: CouponStatus, actorId: string) {
    const existing = await this.prisma.coupon.findUnique({ where: { id: couponId }, select: { id: true, status: true } });
    if (!existing) throw new NotFoundException('Coupon not found');
    if (existing.status === status) return { id: couponId, status };
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.coupon.update({ where: { id: couponId }, data: { status }, select: { id: true, status: true } });
      await tx.auditEvent.create({ data: { actorId, action: 'ADMIN_COUPON_STATUS_CHANGED', entityType: 'COUPON', entityId: couponId, beforeJson: { status: existing.status }, afterJson: { status } } });
      return result;
    });
    return updated;
  }
}