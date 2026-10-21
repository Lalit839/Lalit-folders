import {
  Body,
  Controller,
  Delete,
  Get,
  Post,
  Query,
  UseGuards,
  Headers,
  Param,
  ParseIntPipe,
} from "@nestjs/common";
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from "class-validator";
import { AuthenticatedUser, CurrentUser } from "../auth/current-user.decorator";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import { BookingService } from "./booking.service";

class CreateAttemptDto {
  @IsUUID()
  slotId!: string;

  @IsInt()
  @Min(1)
  quantity!: number;
}

class RescheduleBookingDto {
  @IsUUID()
  slotId!: string;
}

class CancelBookingDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  reason?: string;
}

@Controller()
export class BookingController {
  constructor(private readonly booking: BookingService) {}

  @Get("slots/availability")
  getAvailability(@Query("slotId") slotId: string) {
    return this.booking.getAvailability(slotId);
  }

  @Get("venues/:venueId/availability")
  getVenueAvailability(
    @Param("venueId") venueId: string,
    @Query("date") date?: string,
    @Query("facilityId") facilityId?: string,
  ) {
    return this.booking.getVenueAvailability(venueId, date, facilityId);
  }

  @Get("bookings")
  @UseGuards(JwtAuthGuard)
  getBookings(
    @CurrentUser() user: AuthenticatedUser,
    @Query("status") status?: string,
    @Query("page", new ParseIntPipe({ optional: true })) page = 1,
    @Query("limit", new ParseIntPipe({ optional: true })) limit = 20,
  ) {
    return this.booking.getBookings(user.id, status, page, limit);
  }

  @Get("bookings/:bookingId")
  @UseGuards(JwtAuthGuard)
  getBooking(
    @CurrentUser() user: AuthenticatedUser,
    @Param("bookingId") bookingId: string,
  ) {
    return this.booking.getBooking(user.id, bookingId);
  }

  @Post("booking-attempts")
  @UseGuards(JwtAuthGuard)
  createAttempt(
    @CurrentUser() user: AuthenticatedUser,
    @Headers("idempotency-key") key: string,
    @Body() dto: CreateAttemptDto,
  ) {
    return this.booking.createAttempt(user.id, key, dto.slotId, dto.quantity);
  }

  @Get("booking-attempts/:attemptId")
  @UseGuards(JwtAuthGuard)
  getAttempt(
    @CurrentUser() user: AuthenticatedUser,
    @Param("attemptId") attemptId: string,
  ) {
    return this.booking.getAttempt(user.id, attemptId);
  }

  @Get("coupons")
  @UseGuards(JwtAuthGuard)
  getCoupons(
    @CurrentUser() user: AuthenticatedUser,
    @Query("bookingAttemptId") attemptId?: string,
  ) {
    return this.booking.getEligibleCoupons(user.id, attemptId);
  }

  @Post("booking-attempts/:attemptId/coupon")
  @UseGuards(JwtAuthGuard)
  applyCoupon(
    @CurrentUser() user: AuthenticatedUser,
    @Param("attemptId") attemptId: string,
    @Headers("idempotency-key") key: string,
    @Body("code") code: string,
  ) {
    return this.booking.applyCoupon(user.id, attemptId, key, code);
  }

  @Delete("booking-attempts/:attemptId/coupon")
  @UseGuards(JwtAuthGuard)
  removeCoupon(
    @CurrentUser() user: AuthenticatedUser,
    @Param("attemptId") attemptId: string,
    @Headers("idempotency-key") key: string,
  ) {
    return this.booking.removeCoupon(user.id, attemptId, key);
  }

  @Post("bookings/:bookingId/reschedule")
  @UseGuards(JwtAuthGuard)
  reschedule(
    @CurrentUser() user: AuthenticatedUser,
    @Param("bookingId") bookingId: string,
    @Headers("idempotency-key") key: string,
    @Body() dto: RescheduleBookingDto,
  ) {
    return this.booking.reschedule(user.id, bookingId, key, dto.slotId);
  }

  @Post("bookings/:bookingId/cancel")
  @UseGuards(JwtAuthGuard)
  cancel(
    @CurrentUser() user: AuthenticatedUser,
    @Param("bookingId") bookingId: string,
    @Headers("idempotency-key") key: string,
    @Body() dto: CancelBookingDto,
  ) {
    return this.booking.cancel(user.id, bookingId, key, dto.reason);
  }
}
