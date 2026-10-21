import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  ActivityType,
  ApprovalStatus,
  CatalogueStatus,
  PartnerStatus,
} from "@prisma/client";
import { PrismaService as DatabaseService } from "../database/prisma.service";

type SlotInput = {
  facilityId: string;
  startsAt: string;
  endsAt: string;
  capacity: number;
  pricePaise: number;
};

type ActivityProposalInput = {
  name: string;
  sportCode: string;
  type: ActivityType;
};

@Injectable()
export class InventoryService {
  constructor(private readonly prisma: DatabaseService) {}

  async proposeActivity(userId: string, input: ActivityProposalInput) {
    try {
      return await this.prisma.activity.create({
        data: {
          sportCode: input.sportCode,
          name: input.name,
          type: input.type,
          status: CatalogueStatus.PENDING,
        },
      });
    } catch (err) {
      if ((err as { code?: string }).code === "P2002")
        throw new ConflictException(
          "An activity with this sport code and name already exists",
        );
      throw err;
    }
  }

  async proposeVenueActivity(
    userId: string,
    venueId: string,
    activityId: string,
  ) {
    await this.ensurePartnerVenueScope(userId, venueId);
    const activity = await this.prisma.activity.findFirst({
      where: { id: activityId, status: CatalogueStatus.PUBLISHED },
      select: { id: true },
    });
    if (!activity)
      throw new NotFoundException(
        "Activity not found or not available in the catalogue",
      );
    try {
      return await this.prisma.venueActivity.create({
        data: { venueId, activityId, status: ApprovalStatus.PENDING },
      });
    } catch (err) {
      if ((err as { code?: string }).code === "P2002")
        throw new ConflictException("Activity is already linked to this venue");
      throw err;
    }
  }

  private async ensurePartnerVenueScope(userId: string, venueId: string) {
    const venue = await this.prisma.venue.findFirst({
      where: {
        id: venueId,
        partner: { status: PartnerStatus.ACTIVE, users: { some: { userId } } },
      },
      select: { id: true },
    });
    if (!venue)
      throw new ForbiddenException("Venue is outside your partner scope");
  }
  async createSlot(
    userId: string,
    idempotencyKey: string | undefined,
    input: SlotInput,
  ) {
    if (!idempotencyKey)
      throw new BadRequestException("Idempotency-Key is required");
    const startsAt = new Date(input.startsAt);
    const endsAt = new Date(input.endsAt);
    if (endsAt <= startsAt)
      throw new BadRequestException("Slot end must be after slot start");
    if (startsAt <= new Date())
      throw new BadRequestException("Slot must be in the future");
    if (!Number.isSafeInteger(input.pricePaise))
      throw new BadRequestException("Invalid price");

    const facility = await this.prisma.facility.findFirst({
      where: {
        id: input.facilityId,
        venue: {
          partner: {
            status: PartnerStatus.ACTIVE,
            users: { some: { userId } },
          },
        },
      },
      select: { id: true },
    });
    if (!facility)
      throw new ForbiddenException("Facility is outside your partner scope");
    const existing = await this.prisma.slot.findFirst({
      where: { facilityId: input.facilityId, startsAt, endsAt },
    });
    if (existing) return existing;
    return this.prisma.$transaction(async (tx) => {
      const slot = await tx.slot.create({
        data: {
          facilityId: input.facilityId,
          startsAt,
          endsAt,
          capacity: input.capacity,
          pricePaise: input.pricePaise,
        },
      });
      await tx.auditEvent.create({
        data: {
          actorId: userId,
          action: "INVENTORY_SLOT_CREATED",
          entityType: "slot",
          entityId: slot.id,
          afterJson: {
            facilityId: input.facilityId,
            startsAt,
            endsAt,
            capacity: input.capacity,
            pricePaise: input.pricePaise,
          },
        },
      });
      return slot;
    });
  }

  async blockSlot(userId: string, slotId: string) {
    return this.prisma.$transaction(async (tx) => {
      const slot = await tx.slot.findFirst({
        where: {
          id: slotId,
          facility: {
            venue: {
              partner: {
                status: PartnerStatus.ACTIVE,
                users: { some: { userId } },
              },
            },
          },
        },
      });
      if (!slot) throw new NotFoundException("Slot not found");
      if (slot.bookedQuantity > 0)
        throw new ConflictException("A booked slot cannot be blocked");
      if (slot.status === "BLOCKED") return slot;
      const blocked = await tx.slot.update({
        where: { id: slotId },
        data: { status: "BLOCKED" },
      });
      await tx.auditEvent.create({
        data: {
          actorId: userId,
          action: "INVENTORY_SLOT_BLOCKED",
          entityType: "slot",
          entityId: slotId,
          beforeJson: { status: slot.status },
          afterJson: { status: blocked.status },
        },
      });
      return blocked;
    });
  }
}
