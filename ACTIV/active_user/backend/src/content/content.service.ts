import { Injectable, NotFoundException } from "@nestjs/common";
import { ContentStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";

@Injectable()
export class ContentService {
  constructor(private readonly prisma: PrismaService) {}

  async getPolicy(type: string) {
    const document = await this.prisma.contentDocument.findFirst({
      where: {
        type,
        status: ContentStatus.PUBLISHED,
        publishedAt: { not: null },
      },
      orderBy: { publishedAt: "desc" },
      select: {
        type: true,
        version: true,
        title: true,
        body: true,
        publishedAt: true,
      },
    });
    if (!document) throw new NotFoundException("Policy not found");
    return document;
  }

  getFaqs() {
    return this.prisma.faq.findMany({
      where: { status: ContentStatus.PUBLISHED, publishedAt: { not: null } },
      orderBy: { sortOrder: "asc" },
      select: { id: true, question: true, answer: true },
    });
  }
}
