import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
  UseInterceptors,
} from "@nestjs/common";
import { IsIn, IsNotEmpty, IsString } from "class-validator";
import { ActivityType } from "@prisma/client";
import { AuthenticatedUser, CurrentUser } from "../auth/current-user.decorator";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import { Roles } from "../auth/roles.decorator";
import { RolesGuard } from "../auth/roles.guard";
import { AdminService } from "./admin.service";
import { AdminPerfInterceptor } from "./admin-perf.interceptor";

class CreateActivityDto {
  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsString()
  @IsNotEmpty()
  sportCode!: string;

  @IsIn(Object.values(ActivityType))
  type!: ActivityType;
}

class UpdateActivityDto {
  @IsString()
  @IsNotEmpty()
  name?: string;

  @IsString()
  @IsNotEmpty()
  sportCode?: string;

  @IsIn(Object.values(ActivityType))
  type?: ActivityType;
}

@Controller("admin/catalog")
@UseGuards(JwtAuthGuard, RolesGuard)
@UseInterceptors(AdminPerfInterceptor)
@Roles("ADMIN")
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get("activities")
  listActivities(
    @Query("status") status?: string,
    @Query("type") type?: string,
  ) {
    return this.admin.listActivities(
      status ? AdminService.parseCatalogueStatus(status) : undefined,
      type ? AdminService.parseActivityType(type) : undefined,
    );
  }

  @Post("activities")
  createActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateActivityDto,
  ) {
    return this.admin.createActivity(user.id, dto);
  }

  @Patch("activities/:activityId")
  updateActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("activityId", ParseUUIDPipe) activityId: string,
    @Body() dto: UpdateActivityDto,
  ) {
    return this.admin.updateActivity(user.id, activityId, dto);
  }

  @Post("activities/:activityId/approve")
  approveActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("activityId", ParseUUIDPipe) activityId: string,
  ) {
    return this.admin.approveActivity(user.id, activityId);
  }

  @Post("activities/:activityId/reject")
  rejectActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("activityId", ParseUUIDPipe) activityId: string,
  ) {
    return this.admin.rejectActivity(user.id, activityId);
  }

  @Post("activities/:activityId/activate")
  activateActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("activityId", ParseUUIDPipe) activityId: string,
  ) {
    return this.admin.reactivateActivity(user.id, activityId);
  }

  @Post("activities/:activityId/deactivate")
  deactivateActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("activityId", ParseUUIDPipe) activityId: string,
  ) {
    return this.admin.deactivateActivity(user.id, activityId);
  }

  @Get("venue-activities")
  listVenueActivities(@Query("status") status?: string) {
    return this.admin.listVenueActivities(
      status ? AdminService.parseApprovalStatus(status) : undefined,
    );
  }

  @Post("venues/:venueId/activities/:activityId/approve")
  approveVenueActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Param("activityId", ParseUUIDPipe) activityId: string,
  ) {
    return this.admin.approveVenueActivity(user.id, venueId, activityId);
  }

  @Post("venues/:venueId/activities/:activityId/reject")
  rejectVenueActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("venueId", ParseUUIDPipe) venueId: string,
    @Param("activityId", ParseUUIDPipe) activityId: string,
  ) {
    return this.admin.rejectVenueActivity(user.id, venueId, activityId);
  }
}
