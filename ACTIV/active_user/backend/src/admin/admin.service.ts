import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ActivityType, ApprovalStatus, CatalogueStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";

const ACTIVITY_TYPES: ActivityType[] = Object.values(ActivityType);

type ActivityInput = {
  name: string;
  sportCode: string;
  type: ActivityType;
};

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  listActivities(status?: CatalogueStatus, type?: ActivityType) {
    return this.prisma.activity.findMany({
      where: {
        ...(status ? { status } : {}),
        ...(type ? { type } : {}),
      },
      orderBy: { createdAt: "desc" },
      select: {
        id: true,
        sportCode: true,
        name: true,
        type: true,
        status: true,
        createdAt: true,
      },
    });
  }

  async createActivity(adminId: string, input: ActivityInput) {
    try {
      return await this.prisma.$transaction(async (tx) => {
        const created = await tx.activity.create({
          data: {
            sportCode: input.sportCode,
            name: input.name,
            type: input.type,
            status: CatalogueStatus.PUBLISHED,
          },
        });
        await tx.auditEvent.create({
          data: {
            actorId: adminId,
            action: "CATALOG_ACTIVITY_CREATED",
            entityType: "activity",
            entityId: created.id,
            afterJson: input as unknown as object,
          },
        });
        return created;
      });
    } catch (err) {
      AdminService.ensureUniqueNameConflict(err);
    }
  }

  async updateActivity(
    adminId: string,
    activityId: string,
    input: Partial<ActivityInput>,
  ) {
    const existing = await this.prisma.activity.findUnique({
      where: { id: activityId },
    });
    if (!existing) throw new NotFoundException("Activity not found");
    try {
      return await this.prisma.$transaction(async (tx) => {
        const result = await tx.activity.update({
          where: { id: activityId },
          data: input,
        });
        await tx.auditEvent.create({
          data: {
            actorId: adminId,
            action: "CATALOG_ACTIVITY_UPDATED",
            entityType: "activity",
            entityId: activityId,
            beforeJson: existing as unknown as object,
            afterJson: result as unknown as object,
          },
        });
        return result;
      });
    } catch (err) {
      AdminService.ensureUniqueNameConflict(err);
    }
  }

  async setActivityStatus(
    adminId: string,
    activityId: string,
    status: CatalogueStatus,
  ) {
    const existing = await this.prisma.activity.findUnique({
      where: { id: activityId },
    });
    if (!existing) throw new NotFoundException("Activity not found");
    if (existing.status === status) return existing;
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.activity.update({
        where: { id: activityId },
        data: { status },
      });
      await tx.auditEvent.create({
        data: {
          actorId: adminId,
          action: "CATALOG_ACTIVITY_STATUS_CHANGED",
          entityType: "activity",
          entityId: activityId,
          beforeJson: { status: existing.status },
          afterJson: { status },
        },
      });
      return updated;
    });
  }

  approveActivity(adminId: string, activityId: string) {
    return this.setActivityStatus(
      adminId,
      activityId,
      CatalogueStatus.PUBLISHED,
    );
  }

  rejectActivity(adminId: string, activityId: string) {
    return this.setActivityStatus(
      adminId,
      activityId,
      CatalogueStatus.ARCHIVED,
    );
  }

  deactivateActivity(adminId: string, activityId: string) {
    return this.setActivityStatus(
      adminId,
      activityId,
      CatalogueStatus.ARCHIVED,
    );
  }

  reactivateActivity(adminId: string, activityId: string) {
    return this.setActivityStatus(
      adminId,
      activityId,
      CatalogueStatus.PUBLISHED,
    );
  }

  listVenueActivities(status?: ApprovalStatus) {
    return this.prisma.venueActivity.findMany({
      where: status ? { status } : {},
      orderBy: { venueId: "asc" },
      select: {
        venueId: true,
        activityId: true,
        status: true,
        venue: { select: { id: true, name: true, cityCode: true } },
        activity: {
          select: {
            id: true,
            name: true,
            sportCode: true,
            type: true,
            status: true,
          },
        },
      },
    });
  }

  async setVenueActivityStatus(
    adminId: string,
    venueId: string,
    activityId: string,
    status: ApprovalStatus,
  ) {
    const existing = await this.prisma.venueActivity.findUnique({
      where: { venueId_activityId: { venueId, activityId } },
    });
    if (!existing) throw new NotFoundException("Venue-activity link not found");
    if (existing.status === status) return existing;
    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.venueActivity.update({
        where: { venueId_activityId: { venueId, activityId } },
        data: { status },
      });
      await tx.auditEvent.create({
        data: {
          actorId: adminId,
          action: "CATALOG_VENUE_ACTIVITY_APPROVAL",
          entityType: "venue_activity",
          entityId: `${venueId}:${activityId}`,
          beforeJson: { status: existing.status },
          afterJson: { status },
        },
      });
      return result;
    });
    return updated;
  }

  approveVenueActivity(adminId: string, venueId: string, activityId: string) {
    return this.setVenueActivityStatus(
      adminId,
      venueId,
      activityId,
      ApprovalStatus.APPROVED,
    );
  }

  rejectVenueActivity(adminId: string, venueId: string, activityId: string) {
    return this.setVenueActivityStatus(
      adminId,
      venueId,
      activityId,
      ApprovalStatus.REJECTED,
    );
  }

  static parseActivityType(type: string): ActivityType {
    if (!ACTIVITY_TYPES.includes(type as ActivityType))
      throw new BadRequestException("Invalid activity type");
    return type as ActivityType;
  }

  static parseCatalogueStatus(status: string): CatalogueStatus | undefined {
    const value = Object.values(CatalogueStatus).find((s) => s === status);
    if (!value) throw new BadRequestException("Invalid catalogue status");
    return value;
  }

  static parseApprovalStatus(status: string): ApprovalStatus | undefined {
    const value = Object.values(ApprovalStatus).find((s) => s === status);
    if (!value) throw new BadRequestException("Invalid approval status");
    return value;
  }

  static ensureUniqueNameConflict(err: unknown): never {
    if ((err as { code?: string }).code === "P2002")
      throw new ConflictException(
        "Activity with this sportCode and name already exists",
      );
    throw err;
  }
}
