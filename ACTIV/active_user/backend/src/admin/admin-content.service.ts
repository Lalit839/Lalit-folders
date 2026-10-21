import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ContentStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";

@Injectable()
export class AdminContentService {
  constructor(private readonly prisma: PrismaService) {}

  async listFaqs(status?: ContentStatus) {
    return this.prisma.faq.findMany({
      where: status ? { status } : {},
      orderBy: { sortOrder: "asc" },
      select: {
        id: true,
        question: true,
        answer: true,
        sortOrder: true,
        status: true,
        publishedAt: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async createFaq(
    input: { question: string; answer: string; sortOrder?: number },
    actorId: string,
  ) {
    const faq = await this.prisma.$transaction(async (tx) => {
      const result = await tx.faq.create({
        data: {
          question: input.question.trim(),
          answer: input.answer.trim(),
          sortOrder: input.sortOrder ?? 0,
        },
      });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_FAQ_CREATED",
          entityType: "FAQ",
          entityId: result.id,
          afterJson: { question: result.question },
        },
      });
      return result;
    });
    return faq;
  }

  async updateFaq(
    faqId: string,
    input: Record<string, unknown>,
    actorId: string,
  ) {
    if (!(await this.prisma.faq.findUnique({ where: { id: faqId } })))
      throw new NotFoundException("FAQ not found");
    const data = { ...input };
    if (data.publishedAt !== undefined)
      data.publishedAt = new Date(data.publishedAt as string);
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.faq.update({ where: { id: faqId }, data });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_FAQ_UPDATED",
          entityType: "FAQ",
          entityId: faqId,
          afterJson: {},
        },
      });
      return result;
    });
    return updated;
  }

  async setFaqStatus(faqId: string, status: ContentStatus, actorId: string) {
    if (!(await this.prisma.faq.findUnique({ where: { id: faqId } })))
      throw new NotFoundException("FAQ not found");
    return this.prisma.$transaction(async (tx) => {
      const result = await tx.faq.update({
        where: { id: faqId },
        data: {
          status,
          publishedAt: status === "PUBLISHED" ? new Date() : null,
        },
        select: { id: true, status: true, publishedAt: true },
      });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_FAQ_STATUS_CHANGED",
          entityType: "FAQ",
          entityId: faqId,
          afterJson: { status },
        },
      });
      return result;
    });
  }

  async listPolicies(status?: ContentStatus) {
    return this.prisma.contentDocument.findMany({
      where: status ? { status } : {},
      orderBy: { updatedAt: "desc" },
      select: {
        id: true,
        type: true,
        version: true,
        title: true,
        status: true,
        publishedAt: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async getPolicyById(policyId: string) {
    const doc = await this.prisma.contentDocument.findUnique({
      where: { id: policyId },
    });
    if (!doc) throw new NotFoundException("Policy not found");
    return doc;
  }

  async createPolicy(
    input: { type: string; version: string; title: string; body: string },
    actorId: string,
  ) {
    const existing = await this.prisma.contentDocument.findUnique({
      where: {
        type_version: {
          type: input.type.trim(),
          version: input.version.trim(),
        },
      },
    });
    if (existing)
      throw new BadRequestException(
        "Policy with this type and version already exists",
      );
    return this.prisma.$transaction(async (tx) => {
      const result = await tx.contentDocument.create({
        data: {
          type: input.type.trim(),
          version: input.version.trim(),
          title: input.title.trim(),
          body: input.body,
        },
      });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_POLICY_CREATED",
          entityType: "CONTENT",
          entityId: result.id,
          afterJson: { type: result.type, version: result.version },
        },
      });
      return result;
    });
  }

  async setPolicyStatus(
    policyId: string,
    status: ContentStatus,
    actorId: string,
  ) {
    if (
      !(await this.prisma.contentDocument.findUnique({
        where: { id: policyId },
      }))
    )
      throw new NotFoundException("Policy not found");
    return this.prisma.$transaction(async (tx) => {
      const result = await tx.contentDocument.update({
        where: { id: policyId },
        data: {
          status,
          publishedAt: status === "PUBLISHED" ? new Date() : null,
        },
        select: { id: true, status: true, publishedAt: true },
      });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_POLICY_STATUS_CHANGED",
          entityType: "CONTENT",
          entityId: policyId,
          afterJson: { status },
        },
      });
      return result;
    });
  }
}
