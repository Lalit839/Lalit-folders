import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { BookingStatus, PublishStatus } from "@prisma/client";
import { PrismaService } from "../database/prisma.service";
import { timePerfStage, timeSyncPerfStage } from "../common/perf-timing";

@Injectable()
export class EngagementService {
  constructor(private readonly prisma: PrismaService) {}

  async getSavedVenues(userId: string) {
    const rows = await timePerfStage("engagement.savedVenues.db", () =>
      this.prisma.savedVenue.findMany({
        where: { userId, venue: { status: PublishStatus.PUBLISHED } },
        orderBy: { createdAt: "desc" },
        select: {
          createdAt: true,
          venue: {
            select: {
              id: true,
              name: true,
              cityCode: true,
              latitude: true,
              longitude: true,
              metadata: true,
            },
          },
        },
      }),
    );
    return timeSyncPerfStage("engagement.savedVenues.serialize", () =>
      rows.map(({ venue, createdAt }) => ({
        createdAt,
        venue: venue.metadata
          ? { ...venue, ...(venue.metadata as Record<string, unknown>) }
          : venue,
      })),
    );
  }

  async saveVenue(userId: string, venueId: string) {
    const venue = await this.prisma.venue.findFirst({
      where: { id: venueId, status: PublishStatus.PUBLISHED },
      select: { id: true },
    });
    if (!venue) throw new NotFoundException("Venue not found");
    return this.prisma.savedVenue.upsert({
      where: { userId_venueId: { userId, venueId } },
      create: { userId, venueId },
      update: {},
    });
  }

  async removeSavedVenue(userId: string, venueId: string) {
    await this.prisma.savedVenue.deleteMany({ where: { userId, venueId } });
    return { removed: true };
  }

  async createReview(
    userId: string,
    bookingId: string,
    rating: number,
    body: string,
  ) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, userId },
      select: { id: true, status: true },
    });
    if (!booking) throw new NotFoundException("Booking not found");
    if (booking.status !== BookingStatus.COMPLETED)
      throw new ForbiddenException(
        "Review is available after activity completion",
      );
    const existing = await this.prisma.review.findUnique({
      where: { bookingId },
    });
    if (existing)
      throw new ConflictException("Booking has already been reviewed");
    return this.prisma.review.create({
      data: { bookingId, userId, rating, body },
      select: {
        id: true,
        bookingId: true,
        rating: true,
        body: true,
        status: true,
        createdAt: true,
      },
    });
  }

  async editReview(
    userId: string,
    reviewId: string,
    rating: number,
    body: string,
  ) {
    const review = await this.prisma.review.findFirst({
      where: { id: reviewId, userId },
      select: { id: true },
    });
    if (!review) throw new NotFoundException("Review not found");
    return this.prisma.review.update({
      where: { id: reviewId },
      data: { rating, body },
      select: {
        id: true,
        bookingId: true,
        rating: true,
        body: true,
        status: true,
        updatedAt: true,
      },
    });
  }

  async getCalendar(userId: string, from: string, to: string) {
    const start = new Date(from);
    const end = new Date(to);
    if (
      Number.isNaN(start.valueOf()) ||
      Number.isNaN(end.valueOf()) ||
      end <= start
    )
      throw new BadRequestException("Invalid calendar range");
    return this.prisma.booking.findMany({
      where: {
        userId,
        status: { in: [BookingStatus.CONFIRMED, BookingStatus.RESCHEDULED] },
        startsAt: { gte: start, lt: end },
      },
      orderBy: { startsAt: "asc" },
      select: {
        id: true,
        publicCode: true,
        startsAt: true,
        slot: {
          select: {
            endsAt: true,
            facility: {
              select: {
                name: true,
                venue: { select: { name: true, cityCode: true } },
              },
            },
          },
        },
      },
    });
  }

  async createShareCard(userId: string, from: string, to: string) {
    const activities = await this.getCalendar(userId, from, to);
    return {
      from,
      to,
      activities: activities.map((activity) => ({
        startsAt: activity.startsAt,
        endsAt: activity.slot.endsAt,
        venue: activity.slot.facility.venue.name,
        cityCode: activity.slot.facility.venue.cityCode,
        facility: activity.slot.facility.name,
      })),
    };
  }
}
