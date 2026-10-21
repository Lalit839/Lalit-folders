import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  IsInt,
  IsBoolean,
  Min,
  Max,
} from "class-validator";
import { Type } from "class-transformer";
import {
  BookingStatus,
  PaymentStatus,
  PublishStatus,
  RefundStatus,
  TicketStatus,
  UserStatus,
  ContentStatus,
  CouponStatus,
} from "@prisma/client";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import { RolesGuard } from "../auth/roles.guard";
import { Roles } from "../auth/roles.decorator";
import { CurrentUser, AuthenticatedUser } from "../auth/current-user.decorator";
import { AdminDashboardService } from "./admin-dashboard.service";
import { AdminUsersService } from "./admin-users.service";
import { AdminBookingsService } from "./admin-bookings.service";
import { AdminVenuesService } from "./admin-venues.service";
import { AdminPaymentsService } from "./admin-payments.service";
import { AdminCouponsService } from "./admin-coupons.service";
import { AdminSupportService } from "./admin-support.service";
import { AdminContentService } from "./admin-content.service";
import { AdminNotificationsService } from "./admin-notifications.service";
import { AdminPerfInterceptor } from "./admin-perf.interceptor";
import { VenueUploadFile } from "./cloudinary.service";

class PageQuery {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}

class UsersQuery extends PageQuery {
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;
}

class BookingsQuery extends PageQuery {
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  from?: string;

  @IsOptional()
  @IsString()
  to?: string;
}

class VenuesQuery extends PageQuery {
  @IsOptional()
  @IsEnum(PublishStatus)
  status?: PublishStatus;

  @IsOptional()
  @IsString()
  cityCode?: string;

  @IsOptional()
  @IsString()
  search?: string;
}

class PaymentsQuery extends PageQuery {
  @IsOptional()
  @IsEnum(PaymentStatus)
  status?: PaymentStatus;

  @IsOptional()
  @IsString()
  from?: string;

  @IsOptional()
  @IsString()
  to?: string;
}

class RefundsQuery extends PageQuery {
  @IsOptional()
  @IsIn(["PENDING", "PROCESSED", "FAILED", "EXCEPTION_REVIEW"])
  status?: string;
}

class CouponsQuery extends PageQuery {
  @IsOptional()
  @IsEnum(CouponStatus)
  status?: CouponStatus;
}

class TicketsQuery extends PageQuery {
  @IsOptional()
  @IsEnum(TicketStatus)
  status?: TicketStatus;
}

class StatusDto {
  @IsIn(["ACTIVE", "SUSPENDED", "DELETED"])
  status!: UserStatus;
}

class VenueStatusDto {
  @IsEnum(PublishStatus)
  status!: PublishStatus;
}

class UpdateVenueDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  cityCode?: string;

  @IsOptional()
  latitude?: string | number;

  @IsOptional()
  longitude?: string | number;

  @IsOptional()
  @IsEnum(PublishStatus)
  status?: PublishStatus;

  @IsOptional()
  metadata?: Record<string, unknown>;

  @IsOptional()
  profile?: Record<string, unknown>;
}

class VenueImageDto {
  @IsOptional()
  @IsString()
  url?: string;

  @IsOptional()
  @IsString()
  caption?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;

  @IsOptional()
  metadata?: Record<string, unknown>;
}

class UpdateFacilityDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  capacity?: number;

  @IsOptional()
  @IsString()
  activityId?: string;
}

class TicketStatusDto {
  @IsEnum(TicketStatus)
  status!: TicketStatus;
}

class CancelBookingDto {
  @IsOptional()
  @IsString()
  reason?: string;
}

class InitiateRefundDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  amountPaise!: number;

  @IsOptional()
  @IsString()
  paymentId?: string;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsEnum(RefundStatus)
  status?: RefundStatus;

  @IsOptional()
  @IsString()
  providerRef?: string;
}

class UpdateRefundDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  amountPaise?: number;

  @IsOptional()
  @IsEnum(RefundStatus)
  status?: RefundStatus;

  @IsOptional()
  @IsString()
  providerRef?: string;

  @IsOptional()
  @IsString()
  reason?: string;
}

class CreateCouponDto {
  @IsString()
  code!: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  percentOff?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  amountOffPaise?: number;

  @IsString()
  startsAt!: string;

  @IsString()
  endsAt!: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  maxRedemptions?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  perUserLimit?: number;
}

class UpdateCouponDto {
  @IsOptional()
  @IsString()
  code?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  percentOff?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  amountOffPaise?: number;

  @IsOptional()
  @IsString()
  startsAt?: string;

  @IsOptional()
  @IsString()
  endsAt?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  maxRedemptions?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  perUserLimit?: number;
}

class CouponStatusDto {
  @IsEnum(CouponStatus)
  status!: CouponStatus;
}

class BroadcastDto {
  @IsString()
  title!: string;

  @IsString()
  body!: string;

  @IsOptional()
  @IsString({ each: true })
  userIds?: string[];

  @IsOptional()
  all?: boolean;
}

class CreateFaqDto {
  @IsString()
  question!: string;

  @IsString()
  answer!: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  sortOrder?: number;
}

class UpdateFaqDto {
  @IsOptional()
  @IsString()
  question?: string;

  @IsOptional()
  @IsString()
  answer?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  sortOrder?: number;
}

class CreatePolicyDto {
  @IsString()
  type!: string;

  @IsString()
  version!: string;

  @IsString()
  title!: string;

  @IsString()
  body!: string;
}

class ContentStatusDto {
  @IsEnum(ContentStatus)
  status!: ContentStatus;
}

@Controller("admin")
@UseGuards(JwtAuthGuard, RolesGuard)
@UseInterceptors(AdminPerfInterceptor)
@Roles("ADMIN")
export class AdminApiController {
  constructor(
    private readonly dashboard: AdminDashboardService,
    private readonly users: AdminUsersService,
    private readonly bookings: AdminBookingsService,
    private readonly venues: AdminVenuesService,
    private readonly payments: AdminPaymentsService,
    private readonly coupons: AdminCouponsService,
    private readonly support: AdminSupportService,
    private readonly content: AdminContentService,
    private readonly notifications: AdminNotificationsService,
  ) {}

  @Get("dashboard/overview")
  overview() {
    return this.dashboard.overview();
  }

  @Get("dashboard/revenue")
  revenue(@Query("days") days?: string) {
    return this.dashboard.revenueByDay(days ? Math.max(1, Number(days)) : 30);
  }

  @Get("dashboard/bookings")
  bookingsChart(@Query("days") days?: string) {
    return this.dashboard.bookingsByDay(days ? Math.max(1, Number(days)) : 30);
  }

  @Get("users")
  listUsers(@Query() query: UsersQuery) {
    return this.users.list(query);
  }

  @Get("users/:userId")
  userDetail(@Param("userId", ParseUUIDPipe) userId: string) {
    return this.users.detail(userId);
  }

  @Patch("users/:userId/status")
  userStatus(
    @Param("userId", ParseUUIDPipe) userId: string,
    @Body() dto: StatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.users.updateStatus(userId, dto.status, user.id);
  }

  @Get("bookings")
  listBookings(@Query() query: BookingsQuery) {
    return this.bookings.list(query);
  }

  @Get("bookings/:bookingId")
  bookingDetail(@Param("bookingId", ParseUUIDPipe) bookingId: string) {
    return this.bookings.detail(bookingId);
  }

  @Post("bookings/:bookingId/cancel")
  cancelBooking(
    @Param("bookingId", ParseUUIDPipe) bookingId: string,
    @Body() dto: CancelBookingDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.bookings.cancel(bookingId, user.id, dto.reason);
  }

  @Post("bookings/:bookingId/refunds")
  initiateBookingRefund(
    @Param("bookingId", ParseUUIDPipe) bookingId: string,
    @Body() dto: InitiateRefundDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.bookings.initiateRefund(bookingId, dto, user.id);
  }

  @Patch("bookings/:bookingId/refunds/:refundId")
  updateBookingRefund(
    @Param("bookingId", ParseUUIDPipe) bookingId: string,
    @Param("refundId", ParseUUIDPipe) refundId: string,
    @Body() dto: UpdateRefundDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.bookings.updateRefund(bookingId, refundId, dto, user.id);
  }

  @Get("venues")
  listVenues(@Query() query: VenuesQuery) {
    return this.venues.list(query);
  }

  @Get("venues/:venueId")
  venueDetail(@Param("venueId", ParseUUIDPipe) venueId: string) {
    return this.venues.detail(venueId);
  }

  @Patch("venues/:venueId")
  updateVenue(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Body() dto: UpdateVenueDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.update(
      venueId,
      dto as unknown as Record<string, unknown>,
      user.id,
    );
  }

  @Patch("venues/:venueId/status")
  venueStatus(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Body() dto: VenueStatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.updateStatus(venueId, dto.status, user.id);
  }

  @Post("venues/:venueId/images")
  @UseInterceptors(
    FileInterceptor("image", { limits: { fileSize: 8 * 1024 * 1024 } }),
  )
  addVenueImage(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Body() dto: VenueImageDto,
    @UploadedFile() file: VenueUploadFile | undefined,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.addImage(
      venueId,
      dto as unknown as Record<string, unknown>,
      user.id,
      file,
    );
  }

  @Patch("venues/:venueId/images/:imageId")
  @UseInterceptors(
    FileInterceptor("image", { limits: { fileSize: 8 * 1024 * 1024 } }),
  )
  updateVenueImage(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Param("imageId", ParseUUIDPipe) imageId: string,
    @Body() dto: VenueImageDto,
    @UploadedFile() file: VenueUploadFile | undefined,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.updateImage(
      venueId,
      imageId,
      dto as unknown as Record<string, unknown>,
      user.id,
      file,
    );
  }

  @Delete("venues/:venueId/images/:imageId")
  deleteVenueImage(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Param("imageId", ParseUUIDPipe) imageId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.deleteImage(venueId, imageId, user.id);
  }

  @Patch("venues/:venueId/facilities/:facilityId")
  updateVenueFacility(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Param("facilityId", ParseUUIDPipe) facilityId: string,
    @Body() dto: UpdateFacilityDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.updateFacility(
      venueId,
      facilityId,
      dto as unknown as Record<string, unknown>,
      user.id,
    );
  }

  @Post("venues/:venueId/activities/:activityId")
  addVenueActivity(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Param("activityId", ParseUUIDPipe) activityId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.addActivity(venueId, activityId, user.id);
  }

  @Delete("venues/:venueId/activities/:activityId")
  removeVenueActivity(
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Param("activityId", ParseUUIDPipe) activityId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.venues.removeActivity(venueId, activityId, user.id);
  }

  @Get("payments")
  listPayments(@Query() query: PaymentsQuery) {
    return this.payments.listPayments(query);
  }

  @Get("refunds")
  listRefunds(@Query() query: RefundsQuery) {
    return this.payments.listRefunds(query);
  }

  @Get("coupons")
  listCoupons(@Query() query: CouponsQuery) {
    return this.coupons.list(query);
  }

  @Post("coupons")
  createCoupon(
    @Body() dto: CreateCouponDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.coupons.create(dto, user.id);
  }

  @Patch("coupons/:couponId")
  updateCoupon(
    @Param("couponId", ParseUUIDPipe) couponId: string,
    @Body() dto: UpdateCouponDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.coupons.update(
      couponId,
      dto as unknown as Record<string, unknown>,
      user.id,
    );
  }

  @Patch("coupons/:couponId/status")
  couponStatus(
    @Param("couponId", ParseUUIDPipe) couponId: string,
    @Body() dto: CouponStatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.coupons.setStatus(couponId, dto.status, user.id);
  }

  @Get("support/tickets")
  listTickets(@Query() query: TicketsQuery) {
    return this.support.list(query);
  }

  @Get("support/tickets/:ticketId")
  ticketDetail(@Param("ticketId", ParseUUIDPipe) ticketId: string) {
    return this.support.detail(ticketId);
  }

  @Patch("support/tickets/:ticketId/status")
  ticketStatus(
    @Param("ticketId", ParseUUIDPipe) ticketId: string,
    @Body() dto: TicketStatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.support.updateStatus(ticketId, dto.status, user.id);
  }

  @Get("content/faqs")
  listFaqs(@Query("status") status?: ContentStatus) {
    return this.content.listFaqs(status);
  }

  @Post("content/faqs")
  createFaq(@Body() dto: CreateFaqDto, @CurrentUser() user: AuthenticatedUser) {
    return this.content.createFaq(dto, user.id);
  }

  @Patch("content/faqs/:faqId")
  updateFaq(
    @Param("faqId", ParseUUIDPipe) faqId: string,
    @Body() dto: UpdateFaqDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.content.updateFaq(
      faqId,
      dto as unknown as Record<string, unknown>,
      user.id,
    );
  }

  @Patch("content/faqs/:faqId/status")
  faqStatus(
    @Param("faqId", ParseUUIDPipe) faqId: string,
    @Body() dto: ContentStatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.content.setFaqStatus(faqId, dto.status, user.id);
  }

  @Get("content/policies")
  listPolicies(@Query("status") status?: ContentStatus) {
    return this.content.listPolicies(status);
  }

  @Post("content/policies")
  createPolicy(
    @Body() dto: CreatePolicyDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.content.createPolicy(dto, user.id);
  }

  @Patch("content/policies/:policyId/status")
  policyStatus(
    @Param("policyId", ParseUUIDPipe) policyId: string,
    @Body() dto: ContentStatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.content.setPolicyStatus(policyId, dto.status, user.id);
  }

  @Get("content/policies/:policyId")
  policyDetail(@Param("policyId", ParseUUIDPipe) policyId: string) {
    return this.content.getPolicyById(policyId);
  }

  @Post("notifications/broadcast")
  broadcast(@Body() dto: BroadcastDto) {
    return this.notifications.sendBroadcast(dto);
  }

  @Get("notifications/stats")
  notificationStats() {
    return this.notifications.getNotificationStats();
  }
}
