import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  ApprovalStatus,
  Prisma,
  PublishStatus,
  SlotStatus,
} from "@prisma/client";
import { PrismaService } from "../database/prisma.service";
import {
  CloudinaryService,
  CloudinaryVenueImage,
  VenueUploadFile,
} from "./cloudinary.service";

@Injectable()
export class AdminVenuesService {
  private static readonly partnerSlotHorizonDays = 14;

  constructor(
    private readonly prisma: PrismaService,
    private readonly cloudinary: CloudinaryService,
  ) {}

  async list(params: {
    status?: PublishStatus;
    cityCode?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 20));
    const where: Record<string, unknown> = {};
    if (params.status) where.status = params.status;
    if (params.cityCode) where.cityCode = params.cityCode;
    if (params.search)
      where.name = { contains: params.search.trim(), mode: "insensitive" };
    const [items, total] = await Promise.all([
      this.prisma.venue.findMany({
        where,
        orderBy: { id: "desc" },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          name: true,
          cityCode: true,
          status: true,
          partner: { select: { legalName: true } },
          _count: { select: { activities: true, savedBy: true } },
          activities: { select: { status: true } },
        },
      }),
      this.prisma.venue.count({ where }),
    ]);
    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  async detail(venueId: string) {
    const [
      venue,
      bookingStatusCounts,
      upcomingBookings,
      revenue,
      recentBookings,
      reviewStats,
      recentReviews,
      auditEvents,
    ] = await Promise.all([
      this.prisma.venue.findUnique({
        where: { id: venueId },
        select: {
          id: true,
          name: true,
          cityCode: true,
          latitude: true,
          longitude: true,
          status: true,
          policyVersion: true,
          metadata: true,
          partner: {
            select: {
              id: true,
              legalName: true,
              status: true,
              businessProfile: {
                select: {
                  businessName: true,
                  ownerName: true,
                  phoneE164: true,
                  email: true,
                  addressLine1: true,
                  addressLine2: true,
                  city: true,
                  state: true,
                  postalCode: true,
                  kycStatus: true,
                },
              },
            },
          },
          partnerProfile: true,
          partnerImages: {
            orderBy: [
              { isPrimary: "desc" },
              { sortOrder: "asc" },
              { createdAt: "asc" },
            ],
          },
          _count: {
            select: { savedBy: true, facilities: true, activities: true },
          },
          activities: {
            orderBy: { activity: { name: "asc" } },
            select: {
              status: true,
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
          },
          facilities: {
            orderBy: { name: "asc" },
            select: {
              id: true,
              name: true,
              capacity: true,
              activityId: true,
              activity: {
                select: {
                  id: true,
                  name: true,
                  sportCode: true,
                  type: true,
                  status: true,
                },
              },
              _count: { select: { slots: true } },
              slots: {
                where: { startsAt: { gte: new Date() }, status: "AVAILABLE" },
                orderBy: { startsAt: "asc" },
                take: 1,
                select: {
                  id: true,
                  startsAt: true,
                  endsAt: true,
                  pricePaise: true,
                  status: true,
                },
              },
            },
          },
        },
      }),
      this.prisma.booking.groupBy({
        by: ["status"],
        where: { slot: { facility: { venueId } } },
        _count: { _all: true },
      }),
      this.prisma.booking.count({
        where: {
          startsAt: { gte: new Date() },
          slot: { facility: { venueId } },
        },
      }),
      this.prisma.booking.aggregate({
        where: {
          slot: { facility: { venueId } },
          status: { in: ["CONFIRMED", "COMPLETED"] },
        },
        _sum: { totalPaise: true },
      }),
      this.prisma.booking.findMany({
        where: { slot: { facility: { venueId } } },
        orderBy: { createdAt: "desc" },
        take: 5,
        select: {
          id: true,
          publicCode: true,
          status: true,
          startsAt: true,
          totalPaise: true,
          user: { select: { id: true, name: true, phoneE164: true } },
        },
      }),
      this.prisma.review.aggregate({
        where: {
          booking: { slot: { facility: { venueId } } },
          status: "PUBLISHED",
        },
        _avg: { rating: true },
        _count: { _all: true },
      }),
      this.prisma.review.findMany({
        where: { booking: { slot: { facility: { venueId } } } },
        orderBy: { createdAt: "desc" },
        take: 5,
        select: {
          id: true,
          rating: true,
          body: true,
          status: true,
          createdAt: true,
          user: { select: { id: true, name: true, phoneE164: true } },
        },
      }),
      this.prisma.auditEvent.findMany({
        where: { entityType: "VENUE", entityId: venueId },
        orderBy: { createdAt: "desc" },
        take: 10,
        select: {
          id: true,
          action: true,
          actorId: true,
          beforeJson: true,
          afterJson: true,
          createdAt: true,
        },
      }),
    ]);
    if (!venue) throw new NotFoundException("Venue not found");
    const bookingCount = (status: string) =>
      bookingStatusCounts.find((item) => item.status === status)?._count._all ??
      0;
    return {
      venue: {
        ...venue,
        latitude: venue.latitude.toString(),
        longitude: venue.longitude.toString(),
        facilities: venue.facilities.map((facility) => ({
          ...facility,
          slots: facility.slots.map((slot) => ({
            ...slot,
            pricePaise: slot.pricePaise.toString(),
          })),
        })),
      },
      stats: {
        totalBookings: bookingStatusCounts.reduce(
          (sum, item) => sum + item._count._all,
          0,
        ),
        confirmedBookings: bookingCount("CONFIRMED"),
        completedBookings: bookingCount("COMPLETED"),
        cancelledBookings: bookingCount("CANCELLED"),
        upcomingBookings,
        revenuePaise: (revenue._sum.totalPaise ?? BigInt(0)).toString(),
        savedBy: venue._count.savedBy,
        facilities: venue._count.facilities,
        activities: venue._count.activities,
        averageRating: reviewStats._avg.rating ?? null,
        totalReviews: reviewStats._count._all,
      },
      recentBookings: recentBookings.map((booking) => ({
        ...booking,
        totalPaise: booking.totalPaise.toString(),
      })),
      recentReviews,
      auditEvents,
    };
  }

  async update(
    venueId: string,
    input: Record<string, unknown>,
    actorId: string,
  ) {
    const existing = await this.prisma.venue.findUnique({
      where: { id: venueId },
      select: {
        id: true,
        name: true,
        cityCode: true,
        latitude: true,
        longitude: true,
        status: true,
        metadata: true,
        partnerId: true,
        partnerProfile: true,
      },
    });
    if (!existing) throw new NotFoundException("Venue not found");

    const venueData: Prisma.VenueUpdateInput = {};
    if (input.name !== undefined)
      venueData.name = this.cleanString(input.name, "name");
    if (input.cityCode !== undefined)
      venueData.cityCode = this.cleanString(
        input.cityCode,
        "cityCode",
      ).toUpperCase();
    if (input.latitude !== undefined)
      venueData.latitude = this.coordinate(input.latitude, "latitude", -90, 90);
    if (input.longitude !== undefined)
      venueData.longitude = this.coordinate(
        input.longitude,
        "longitude",
        -180,
        180,
      );
    if (input.status !== undefined)
      venueData.status = this.publishStatus(input.status);
    if (input.metadata !== undefined)
      venueData.metadata = this.jsonValue(input.metadata, "metadata");

    const profileInput = this.jsonObject(input.profile ?? {}, "profile");
    const businessInput = this.jsonObject(
      input.businessProfile ?? {},
      "businessProfile",
    );
    const profileData: Prisma.PartnerVenueProfileUpdateInput = {};
    const profileCreate: Prisma.PartnerVenueProfileCreateInput = {
      partner: { connect: { id: existing.partnerId } },
      venue: { connect: { id: venueId } },
    };
    const assignProfile = (
      key: keyof Prisma.PartnerVenueProfileUpdateInput,
      value: unknown,
    ) => {
      if (value !== undefined) {
        const cleaned = value === null ? null : String(value).trim();
        profileData[key] = cleaned as never;
        (profileCreate as Record<string, unknown>)[key as string] = cleaned;
      }
    };
    assignProfile("displayName", profileInput.displayName);
    assignProfile("description", profileInput.description);
    assignProfile("contactPhoneE164", profileInput.contactPhoneE164);
    assignProfile("contactEmail", profileInput.contactEmail);
    assignProfile("addressLine1", profileInput.addressLine1);
    assignProfile("addressLine2", profileInput.addressLine2);
    assignProfile("city", profileInput.city);
    assignProfile("state", profileInput.state);
    assignProfile("postalCode", profileInput.postalCode);
    if (profileInput.amenities !== undefined) {
      profileData.amenities = this.jsonValue(
        profileInput.amenities,
        "amenities",
      );
      profileCreate.amenities = this.jsonValue(
        profileInput.amenities,
        "amenities",
      );
    }
    if (profileInput.operatingHours !== undefined) {
      profileData.operatingHours = this.jsonValue(
        profileInput.operatingHours,
        "operatingHours",
      );
      profileCreate.operatingHours = this.jsonValue(
        profileInput.operatingHours,
        "operatingHours",
      );
    }
    const businessData: Prisma.PartnerBusinessProfileUpdateInput = {};
    const businessCreate: Prisma.PartnerBusinessProfileCreateInput = {
      partner: { connect: { id: existing.partnerId } },
    };
    const assignBusiness = (
      key: keyof Prisma.PartnerBusinessProfileUpdateInput,
      value: unknown,
    ) => {
      if (value !== undefined) {
        const cleaned = value === null ? null : String(value).trim();
        businessData[key] = cleaned as never;
        (businessCreate as Record<string, unknown>)[key as string] = cleaned;
      }
    };
    assignBusiness("businessName", businessInput.businessName);
    assignBusiness("ownerName", businessInput.ownerName);
    assignBusiness("phoneE164", businessInput.phoneE164);
    assignBusiness("email", businessInput.email);
    assignBusiness("addressLine1", businessInput.addressLine1);
    assignBusiness("addressLine2", businessInput.addressLine2);
    assignBusiness("city", businessInput.city);
    assignBusiness("state", businessInput.state);
    assignBusiness("postalCode", businessInput.postalCode);

    const updated = await this.prisma.$transaction(async (tx) => {
      const result = Object.keys(venueData).length
        ? await tx.venue.update({
            where: { id: venueId },
            data: venueData,
            select: { id: true },
          })
        : { id: venueId };
      if (Object.keys(profileData).length) {
        await tx.partnerVenueProfile.upsert({
          where: { venueId },
          update: profileData,
          create: profileCreate,
        });
      }
      if (Object.keys(businessData).length) {
        await tx.partnerBusinessProfile.upsert({
          where: { partnerId: existing.partnerId },
          update: businessData,
          create: businessCreate,
        });
      }
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_VENUE_UPDATED",
          entityType: "VENUE",
          entityId: venueId,
          beforeJson: {
            id: existing.id,
            name: existing.name,
            cityCode: existing.cityCode,
            latitude: existing.latitude.toString(),
            longitude: existing.longitude.toString(),
            status: existing.status,
            metadata: existing.metadata ?? null,
            partnerProfile: existing.partnerProfile ?? null,
          } as Prisma.InputJsonObject,
          afterJson: this.auditJson(input),
        },
      });
      return result;
    });
    return this.detail(updated.id);
  }

  async updateFacility(
    venueId: string,
    facilityId: string,
    input: Record<string, unknown>,
    actorId: string,
  ) {
    const existing = await this.prisma.facility.findFirst({
      where: { id: facilityId, venueId },
      select: { id: true, name: true, capacity: true, activityId: true },
    });
    if (!existing) throw new NotFoundException("Facility not found");

    const data: Prisma.FacilityUpdateInput = {};
    if (input.name !== undefined)
      data.name = this.cleanString(input.name, "facility name");
    if (input.capacity !== undefined) {
      const capacity = Number(input.capacity);
      if (!Number.isInteger(capacity) || capacity < 1)
        throw new BadRequestException("Invalid facility capacity");
      data.capacity = capacity;
    }
    if (input.activityId !== undefined) {
      const activityId = this.cleanString(input.activityId, "activityId");
      const activity = await this.prisma.activity.findUnique({
        where: { id: activityId },
        select: { id: true },
      });
      if (!activity) throw new BadRequestException("Activity not found");
      data.activity = { connect: { id: activityId } };
    }
    if (!Object.keys(data).length) return this.detail(venueId);

    await this.prisma.$transaction(async (tx) => {
      await tx.facility.update({ where: { id: facilityId }, data });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_VENUE_FACILITY_UPDATED",
          entityType: "VENUE",
          entityId: venueId,
          beforeJson: existing,
          afterJson: this.auditJson(input),
        },
      });
    });
    return this.detail(venueId);
  }

  async addImage(
    venueId: string,
    input: Record<string, unknown>,
    actorId: string,
    file?: VenueUploadFile,
  ) {
    const venue = await this.prisma.venue.findUnique({
      where: { id: venueId },
      select: { id: true },
    });
    if (!venue) throw new NotFoundException("Venue not found");
    const uploaded = file
      ? await this.cloudinary.uploadVenueImage(file, venueId)
      : null;
    const url = uploaded?.secureUrl ?? this.cleanUrl(input.url);
    try {
      const image = await this.prisma.$transaction(async (tx) => {
        if (input.isPrimary === true)
          await tx.partnerVenueImage.updateMany({
            where: { venueId },
            data: { isPrimary: false },
          });
        const max = await tx.partnerVenueImage.aggregate({
          where: { venueId },
          _max: { sortOrder: true },
        });
        const created = await tx.partnerVenueImage.create({
          data: {
            venueId,
            url,
            caption: input.caption ? String(input.caption).trim() : null,
            sortOrder: Number(input.sortOrder ?? (max._max.sortOrder ?? 0) + 1),
            isPrimary: input.isPrimary === true,
            metadata: uploaded
              ? this.cloudinaryMetadata(uploaded, input.metadata)
              : this.jsonValue(input.metadata ?? {}, "metadata"),
          },
        });
        await tx.auditEvent.create({
          data: {
            actorId,
            action: "ADMIN_VENUE_IMAGE_ADDED",
            entityType: "VENUE",
            entityId: venueId,
            afterJson: {
              imageId: created.id,
              url,
              cloudinaryPublicId: uploaded?.publicId,
            },
          },
        });
        return created;
      });
      return image;
    } catch (error) {
      if (uploaded)
        await this.cloudinary
          .deleteVenueImage(uploaded.publicId)
          .catch(() => undefined);
      throw error;
    }
  }

  async updateImage(
    venueId: string,
    imageId: string,
    input: Record<string, unknown>,
    actorId: string,
    file?: VenueUploadFile,
  ) {
    const existing = await this.prisma.partnerVenueImage.findFirst({
      where: { id: imageId, venueId },
    });
    if (!existing) throw new NotFoundException("Image not found");
    const oldPublicId = this.cloudinaryPublicId(existing.metadata);
    const uploaded = file
      ? await this.cloudinary.uploadVenueImage(file, venueId)
      : null;
    try {
      const image = await this.prisma.$transaction(async (tx) => {
        if (input.isPrimary === true)
          await tx.partnerVenueImage.updateMany({
            where: { venueId },
            data: { isPrimary: false },
          });
        const updated = await tx.partnerVenueImage.update({
          where: { id: imageId },
          data: {
            ...(uploaded
              ? {
                  url: uploaded.secureUrl,
                  metadata: this.cloudinaryMetadata(uploaded, input.metadata),
                }
              : {}),
            ...(input.url !== undefined && !uploaded
              ? { url: this.cleanUrl(input.url) }
              : {}),
            ...(input.caption !== undefined
              ? { caption: input.caption ? String(input.caption).trim() : null }
              : {}),
            ...(input.sortOrder !== undefined
              ? { sortOrder: Number(input.sortOrder) }
              : {}),
            ...(input.isPrimary !== undefined
              ? { isPrimary: input.isPrimary === true }
              : {}),
          },
        });
        await tx.auditEvent.create({
          data: {
            actorId,
            action: uploaded
              ? "ADMIN_VENUE_IMAGE_REPLACED"
              : "ADMIN_VENUE_IMAGE_UPDATED",
            entityType: "VENUE",
            entityId: venueId,
            beforeJson: {
              id: existing.id,
              url: existing.url,
              caption: existing.caption,
              sortOrder: existing.sortOrder,
              isPrimary: existing.isPrimary,
              cloudinaryPublicId: oldPublicId,
            },
            afterJson: this.auditJson({
              ...input,
              cloudinaryPublicId: uploaded?.publicId,
            }),
          },
        });
        return updated;
      });
      if (uploaded && oldPublicId && oldPublicId !== uploaded.publicId) {
        await this.cloudinary
          .deleteVenueImage(oldPublicId)
          .catch(() => undefined);
      }
      return image;
    } catch (error) {
      if (uploaded)
        await this.cloudinary
          .deleteVenueImage(uploaded.publicId)
          .catch(() => undefined);
      throw error;
    }
  }

  async deleteImage(venueId: string, imageId: string, actorId: string) {
    const existing = await this.prisma.partnerVenueImage.findFirst({
      where: { id: imageId, venueId },
    });
    if (!existing) throw new NotFoundException("Image not found");
    await this.cloudinary.deleteVenueImage(
      this.cloudinaryPublicId(existing.metadata),
    );
    await this.prisma.$transaction(async (tx) => {
      await tx.partnerVenueImage.delete({ where: { id: imageId } });
      if (existing.isPrimary) {
        const replacement = await tx.partnerVenueImage.findFirst({
          where: { venueId },
          orderBy: [{ sortOrder: "asc" }, { createdAt: "asc" }],
        });
        if (replacement)
          await tx.partnerVenueImage.update({
            where: { id: replacement.id },
            data: { isPrimary: true },
          });
      }
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_VENUE_IMAGE_REMOVED",
          entityType: "VENUE",
          entityId: venueId,
          beforeJson: {
            id: existing.id,
            url: existing.url,
            caption: existing.caption,
            sortOrder: existing.sortOrder,
            isPrimary: existing.isPrimary,
          },
        },
      });
    });
    return { success: true };
  }

  async addActivity(venueId: string, activityId: string, actorId: string) {
    await this.prisma.$transaction(async (tx) => {
      await tx.venueActivity.upsert({
        where: { venueId_activityId: { venueId, activityId } },
        update: { status: ApprovalStatus.APPROVED },
        create: { venueId, activityId, status: ApprovalStatus.APPROVED },
      });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_VENUE_ACTIVITY_ADDED",
          entityType: "VENUE",
          entityId: venueId,
          afterJson: { activityId },
        },
      });
    });
    return this.detail(venueId);
  }

  async removeActivity(venueId: string, activityId: string, actorId: string) {
    await this.prisma.$transaction(async (tx) => {
      await tx.venueActivity.delete({
        where: { venueId_activityId: { venueId, activityId } },
      });
      await tx.auditEvent.create({
        data: {
          actorId,
          action: "ADMIN_VENUE_ACTIVITY_REMOVED",
          entityType: "VENUE",
          entityId: venueId,
          beforeJson: { activityId },
        },
      });
    });
    return this.detail(venueId);
  }

  async updateStatus(venueId: string, status: PublishStatus, actorId: string) {
    const existing = await this.prisma.venue.findUnique({
      where: { id: venueId },
      select: { id: true, status: true },
    });
    if (!existing) throw new NotFoundException("Venue not found");
    if (existing.status === status) {
      if (status === PublishStatus.PUBLISHED)
        await this.syncPartnerBookingInventory(venueId, actorId);
      return { id: venueId, status };
    }
    const updated = await this.prisma.$transaction(
      async (tx) => {
        const result = await tx.venue.update({
          where: { id: venueId },
          data: { status },
          select: { id: true, status: true },
        });
        if (status === PublishStatus.PUBLISHED)
          await this.syncPartnerBookingInventoryForTransaction(tx, venueId);
        await tx.auditEvent.create({
          data: {
            actorId,
            action: "ADMIN_VENUE_STATUS_CHANGED",
            entityType: "VENUE",
            entityId: venueId,
            beforeJson: { status: existing.status },
            afterJson: { status },
          },
        });
        return result;
      },
      { timeout: 30000 },
    );
    return updated;
  }

  private async syncPartnerBookingInventory(venueId: string, actorId: string) {
    await this.prisma.$transaction(
      async (tx) => {
        await this.syncPartnerBookingInventoryForTransaction(tx, venueId);
        await tx.auditEvent.create({
          data: {
            actorId,
            action: "ADMIN_VENUE_PARTNER_INVENTORY_SYNCED",
            entityType: "VENUE",
            entityId: venueId,
            afterJson: { venueId },
          },
        });
      },
      { timeout: 30000 },
    );
  }

  private async syncPartnerBookingInventoryForTransaction(
    tx: Prisma.TransactionClient,
    venueId: string,
  ) {
    const venue = await tx.venue.findUnique({
      where: { id: venueId },
      select: { id: true, status: true },
    });
    if (!venue || venue.status !== PublishStatus.PUBLISHED) return;

    const services = await tx.$queryRaw<
      Array<{
        id: string;
        venue_id: string;
        facility_id: string | null;
        service_category_id: string;
        title: string;
        status: string;
        is_active: boolean;
        capacity: number | null;
        duration_minutes: number | null;
        min_duration_minutes: number | null;
        max_duration_minutes: number | null;
        activity_id: string | null;
        activity_name: string | null;
      }>
    >`
      select
        pvs.id,
        pvs.venue_id,
        pvs.facility_id,
        pvs.service_category_id,
        pvs.title,
        pvs.status::text as status,
        pvs.is_active,
        pvs.capacity,
        pvs.duration_minutes,
        pvs.min_duration_minutes,
        pvs.max_duration_minutes,
        activity.id as activity_id,
        activity.name as activity_name
      from partner_venue_services pvs
      join partner_service_categories psc on psc.id = pvs.service_category_id
      left join lateral (
        select a.id, a.name
        from activities a
        where a.status = 'PUBLISHED'::"CatalogueStatus"
          and (
            lower(a.sport_code) = lower(psc.slug)
            or lower(a.name) = lower(psc.name)
            or lower(a.name) = lower(pvs.title)
            or lower(a.sport_code) = lower(regexp_replace(pvs.title, '[^a-zA-Z0-9]+', '_', 'g'))
          )
        order by
          case
            when lower(a.sport_code) = lower(psc.slug) then 0
            when lower(a.name) = lower(psc.name) then 1
            when lower(a.name) = lower(pvs.title) then 2
            else 3
          end,
          a.name asc
        limit 1
      ) activity on true
      where pvs.venue_id = ${venueId}::uuid
    `;

    for (const service of services) {
      if (
        service.status !== "APPROVED" ||
        !service.is_active ||
        !service.activity_id
      ) {
        if (service.facility_id) {
          await this.blockFutureUnbookedSlots(tx, service.facility_id);
        }
        continue;
      }

      await tx.venueActivity.upsert({
        where: {
          venueId_activityId: {
            venueId,
            activityId: service.activity_id,
          },
        },
        update: { status: ApprovalStatus.APPROVED },
        create: {
          venueId,
          activityId: service.activity_id,
          status: ApprovalStatus.APPROVED,
        },
      });

      const availability = await tx.$queryRaw<
        Array<{
          day: string;
          open_time: string;
          close_time: string;
          capacity: number;
          price_paise: bigint;
          discounted_price_paise: bigint;
        }>
      >`
        select day, open_time, close_time, capacity, price_paise, discounted_price_paise
        from partner_venue_availability
        where venue_id = ${venueId}::uuid
          and service_category_id = ${service.service_category_id}::uuid
        order by sort_order asc, day asc, open_time asc
      `;
      if (!availability.length) continue;

      const capacity = this.partnerServiceCapacity(
        service.capacity,
        availability,
      );
      if (capacity < 1) continue;

      const facility = await this.upsertPartnerServiceFacility(tx, {
        venueId,
        activityId: service.activity_id,
        existingFacilityId: service.facility_id,
        name: service.title,
        capacity,
      });

      if (facility.id !== service.facility_id) {
        await tx.$executeRaw`
          update partner_venue_services
          set facility_id = ${facility.id}::uuid,
              updated_at = now()
          where id = ${service.id}::uuid
        `;
      }

      await this.syncPartnerServiceSlots(tx, {
        venueServiceId: service.id,
        facilityId: facility.id,
        durationMinutes: this.partnerServiceDurationMinutes(service),
        availability,
      });
    }
  }

  private async upsertPartnerServiceFacility(
    tx: Prisma.TransactionClient,
    input: {
      venueId: string;
      activityId: string;
      existingFacilityId: string | null;
      name: string;
      capacity: number;
    },
  ) {
    if (input.existingFacilityId) {
      const existing = await tx.facility.findFirst({
        where: { id: input.existingFacilityId, venueId: input.venueId },
        select: { id: true },
      });
      if (existing) {
        return tx.facility.update({
          where: { id: existing.id },
          data: {
            activityId: input.activityId,
            name: input.name,
            capacity: input.capacity,
          },
          select: { id: true },
        });
      }
    }

    const matching = await tx.facility.findFirst({
      where: {
        venueId: input.venueId,
        activityId: input.activityId,
        name: input.name,
      },
      select: { id: true },
    });
    if (matching) {
      return tx.facility.update({
        where: { id: matching.id },
        data: { capacity: input.capacity },
        select: { id: true },
      });
    }

    return tx.facility.create({
      data: {
        venueId: input.venueId,
        activityId: input.activityId,
        name: input.name,
        capacity: input.capacity,
      },
      select: { id: true },
    });
  }

  private async syncPartnerServiceSlots(
    tx: Prisma.TransactionClient,
    input: {
      venueServiceId: string;
      facilityId: string;
      durationMinutes: number;
      availability: Array<{
        day: string;
        open_time: string;
        close_time: string;
        capacity: number;
        price_paise: bigint;
        discounted_price_paise: bigint;
      }>;
    },
  ) {
    const desiredSlots = this.partnerDesiredSlots(
      input.availability,
      input.durationMinutes,
    );
    const desiredKeys = new Set(
      desiredSlots.map((slot) => this.slotKey(slot.startsAt, slot.endsAt)),
    );

    for (const desired of desiredSlots) {
      const existing = await tx.slot.findFirst({
        where: {
          facilityId: input.facilityId,
          startsAt: desired.startsAt,
          endsAt: desired.endsAt,
        },
        select: { id: true, bookedQuantity: true },
      });
      if (existing) {
        if (existing.bookedQuantity === 0) {
          await tx.slot.update({
            where: { id: existing.id },
            data: {
              capacity: desired.capacity,
              pricePaise: desired.pricePaise,
              status: SlotStatus.AVAILABLE,
            },
          });
        }
        continue;
      }

      await tx.slot.create({
        data: {
          facilityId: input.facilityId,
          startsAt: desired.startsAt,
          endsAt: desired.endsAt,
          capacity: desired.capacity,
          bookedQuantity: 0,
          status: SlotStatus.AVAILABLE,
          pricePaise: desired.pricePaise,
        },
      });
    }

    const futureSlots = await tx.slot.findMany({
      where: {
        facilityId: input.facilityId,
        startsAt: { gt: new Date() },
      },
      select: { id: true, startsAt: true, endsAt: true, bookedQuantity: true },
    });
    for (const slot of futureSlots) {
      if (
        !desiredKeys.has(this.slotKey(slot.startsAt, slot.endsAt)) &&
        slot.bookedQuantity === 0
      ) {
        await tx.slot.update({
          where: { id: slot.id },
          data: { status: SlotStatus.BLOCKED },
        });
      }
    }

    await tx.$executeRaw`
      update slots
      set status = 'BLOCKED'::"SlotStatus"
      where booked_quantity = 0
        and starts_at > now()
        and id in (
          select slot_id
          from partner_service_paused_slots
          where venue_service_id = ${input.venueServiceId}::uuid
        )
    `;
  }

  private async blockFutureUnbookedSlots(
    tx: Prisma.TransactionClient,
    facilityId: string,
  ) {
    await tx.slot.updateMany({
      where: {
        facilityId,
        startsAt: { gt: new Date() },
        bookedQuantity: 0,
      },
      data: { status: SlotStatus.BLOCKED },
    });
  }

  private partnerDesiredSlots(
    availability: Array<{
      day: string;
      open_time: string;
      close_time: string;
      capacity: number;
      price_paise: bigint;
      discounted_price_paise: bigint;
    }>,
    durationMinutes: number,
  ) {
    const slots: Array<{
      startsAt: Date;
      endsAt: Date;
      capacity: number;
      pricePaise: bigint;
    }> = [];
    const now = new Date();
    for (
      let offset = 0;
      offset < AdminVenuesService.partnerSlotHorizonDays;
      offset += 1
    ) {
      const day = this.istDateForOffset(now, offset);
      const weekday = this.weekdayName(day);
      for (const row of availability) {
        if (row.day.trim().toLowerCase() !== weekday) continue;
        const open = this.parsePartnerTime(row.open_time);
        const close = this.parsePartnerTime(row.close_time);
        if (!open || !close) continue;

        let cursorMinutes = open.hours * 60 + open.minutes;
        const closeMinutes = close.hours * 60 + close.minutes;
        while (cursorMinutes + durationMinutes <= closeMinutes) {
          const startsAt = this.istWallTimeToUtc(day, cursorMinutes);
          const endsAt = this.istWallTimeToUtc(
            day,
            cursorMinutes + durationMinutes,
          );
          if (startsAt > now && row.capacity > 0) {
            slots.push({
              startsAt,
              endsAt,
              capacity: row.capacity,
              pricePaise:
                row.discounted_price_paise > BigInt(0)
                  ? row.discounted_price_paise
                  : row.price_paise,
            });
          }
          cursorMinutes += durationMinutes;
        }
      }
    }
    return slots;
  }

  private partnerServiceDurationMinutes(service: {
    duration_minutes: number | null;
    min_duration_minutes: number | null;
    max_duration_minutes: number | null;
  }) {
    const duration =
      service.duration_minutes ??
      service.min_duration_minutes ??
      service.max_duration_minutes ??
      60;
    return Number.isInteger(duration) && duration > 0 ? duration : 60;
  }

  private partnerServiceCapacity(
    serviceCapacity: number | null,
    availability: Array<{ capacity: number }>,
  ) {
    const capacities = [
      serviceCapacity,
      ...availability.map((row) => row.capacity),
    ].filter(
      (capacity): capacity is number =>
        capacity !== null && Number.isInteger(capacity) && capacity > 0,
    );
    return capacities.length ? Math.max(...capacities) : 0;
  }

  private parsePartnerTime(value: string) {
    const match = value.trim().match(/^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$/i);
    if (!match) return null;
    let hours = Number(match[1]);
    const minutes = Number(match[2] ?? 0);
    const meridiem = match[3]?.toUpperCase();
    if (
      !Number.isInteger(hours) ||
      !Number.isInteger(minutes) ||
      minutes < 0 ||
      minutes > 59
    )
      return null;
    if (meridiem) {
      if (hours < 1 || hours > 12) return null;
      if (meridiem === "AM") hours = hours === 12 ? 0 : hours;
      if (meridiem === "PM") hours = hours === 12 ? 12 : hours + 12;
    }
    if (hours < 0 || hours > 23) return null;
    return { hours, minutes };
  }

  private istDateForOffset(now: Date, offset: number) {
    const istNow = new Date(now.getTime() + 330 * 60 * 1000);
    return new Date(
      Date.UTC(
        istNow.getUTCFullYear(),
        istNow.getUTCMonth(),
        istNow.getUTCDate() + offset,
      ),
    );
  }

  private istWallTimeToUtc(day: Date, minutesFromMidnight: number) {
    const hours = Math.floor(minutesFromMidnight / 60);
    const minutes = minutesFromMidnight % 60;
    return new Date(
      Date.UTC(
        day.getUTCFullYear(),
        day.getUTCMonth(),
        day.getUTCDate(),
        hours - 5,
        minutes - 30,
      ),
    );
  }

  private weekdayName(day: Date) {
    return [
      "sunday",
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
    ][day.getUTCDay()];
  }

  private slotKey(startsAt: Date, endsAt: Date) {
    return `${startsAt.toISOString()}|${endsAt.toISOString()}`;
  }

  private cleanString(value: unknown, field: string) {
    if (typeof value !== "string" || !value.trim())
      throw new BadRequestException(`${field} is required`);
    return value.trim();
  }

  private cleanUrl(value: unknown) {
    if (typeof value !== "string" || !/^https?:\/\//i.test(value.trim()))
      throw new BadRequestException("Valid image URL is required");
    return value.trim();
  }

  private coordinate(value: unknown, field: string, min: number, max: number) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed < min || parsed > max)
      throw new BadRequestException(`Invalid ${field}`);
    return new Prisma.Decimal(parsed);
  }

  private publishStatus(value: unknown) {
    if (!Object.values(PublishStatus).includes(value as PublishStatus))
      throw new BadRequestException("Invalid venue status");
    return value as PublishStatus;
  }

  private jsonObject(value: unknown, field: string): Record<string, unknown> {
    if (value === undefined || value === null) return {};
    if (typeof value !== "object" || Array.isArray(value))
      throw new BadRequestException(`${field} must be an object`);
    return value as Record<string, unknown>;
  }

  private jsonValue(value: unknown, field: string): Prisma.InputJsonValue {
    if (value === undefined) return {};
    if (value === null) return {};
    if (typeof value !== "object")
      throw new BadRequestException(`${field} must be an object`);
    return value as Prisma.InputJsonValue;
  }

  private auditJson(value: unknown): Prisma.InputJsonValue {
    return JSON.parse(JSON.stringify(value ?? {})) as Prisma.InputJsonValue;
  }

  private cloudinaryMetadata(
    uploaded: CloudinaryVenueImage,
    extra: unknown,
  ): Prisma.InputJsonValue {
    const extraMetadata = this.jsonObject(extra ?? {}, "metadata");
    return {
      ...extraMetadata,
      provider: "cloudinary",
      secureUrl: uploaded.secureUrl,
      optimizedUrl: uploaded.optimizedUrl,
      cloudinaryPublicId: uploaded.publicId,
      resourceType: uploaded.resourceType,
      format: uploaded.format,
      width: uploaded.width,
      height: uploaded.height,
      bytes: uploaded.bytes,
    } as Prisma.InputJsonObject;
  }

  private cloudinaryPublicId(metadata: unknown) {
    if (!metadata || typeof metadata !== "object" || Array.isArray(metadata))
      return null;
    const value = (metadata as Record<string, unknown>).cloudinaryPublicId;
    return typeof value === "string" && value.trim() ? value : null;
  }
}
