import { Controller, Get, Param, Query, UseGuards } from "@nestjs/common";
import { AuthenticatedUser, CurrentUser } from "../auth/current-user.decorator";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import { Roles } from "../auth/roles.decorator";
import { RolesGuard } from "../auth/roles.guard";
import { BookingService } from "./booking.service";

@Controller("partner/bookings")
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles("PARTNER_USER", "PARTNER_ADMIN")
export class PartnerBookingController {
  constructor(private readonly booking: BookingService) {}

  @Get()
  list(
    @CurrentUser() user: AuthenticatedUser,
    @Query("status") status?: string,
  ) {
    return this.booking.getPartnerBookings(user.id, status);
  }

  @Get(":bookingId")
  detail(
    @CurrentUser() user: AuthenticatedUser,
    @Param("bookingId") bookingId: string,
  ) {
    return this.booking.getPartnerBooking(user.id, bookingId);
  }
}
