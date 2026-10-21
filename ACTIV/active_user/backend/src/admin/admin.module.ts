import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module";
import { NotificationsModule } from "../notifications/notifications.module";
import { AdminController } from "./admin.controller";
import { AdminService } from "./admin.service";
import { AdminAuthController } from "./admin-auth.controller";
import { AdminAuthService } from "./admin-auth.service";
import { AdminApiController } from "./admin-api.controller";
import { AdminDashboardService } from "./admin-dashboard.service";
import { AdminUsersService } from "./admin-users.service";
import { AdminBookingsService } from "./admin-bookings.service";
import { AdminVenuesService } from "./admin-venues.service";
import { AdminPaymentsService } from "./admin-payments.service";
import { AdminCouponsService } from "./admin-coupons.service";
import { AdminSupportService } from "./admin-support.service";
import { AdminContentService } from "./admin-content.service";
import { AdminNotificationsService } from "./admin-notifications.service";
import { CloudinaryService } from "./cloudinary.service";

@Module({
  imports: [AuthModule, NotificationsModule],
  controllers: [AdminController, AdminAuthController, AdminApiController],
  providers: [
    AdminService,
    AdminAuthService,
    AdminDashboardService,
    AdminUsersService,
    AdminBookingsService,
    AdminVenuesService,
    AdminPaymentsService,
    AdminCouponsService,
    AdminSupportService,
    AdminContentService,
    AdminNotificationsService,
    CloudinaryService,
  ],
})
export class AdminModule {}
