import {
  Body,
  Controller,
  Headers,
  Param,
  Post,
  UseGuards,
} from "@nestjs/common";
import {
  IsDateString,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsString,
  IsUUID,
  Min,
} from "class-validator";
import { ActivityType } from "@prisma/client";
import { AuthenticatedUser, CurrentUser } from "../auth/current-user.decorator";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import { Roles } from "../auth/roles.decorator";
import { RolesGuard } from "../auth/roles.guard";
import { InventoryService } from "./inventory.service";

class CreateSlotDto {
  @IsUUID()
  facilityId!: string;

  @IsDateString()
  startsAt!: string;

  @IsDateString()
  endsAt!: string;

  @IsInt()
  @Min(1)
  capacity!: number;

  @IsInt()
  @Min(0)
  pricePaise!: number;
}

class ProposeActivityDto {
  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsString()
  @IsNotEmpty()
  sportCode!: string;

  @IsIn(Object.values(ActivityType))
  type!: ActivityType;
}

@Controller("partner/inventory")
@UseGuards(JwtAuthGuard)
@UseGuards(RolesGuard)
@Roles("PARTNER_USER", "PARTNER_ADMIN")
export class InventoryController {
  constructor(private readonly inventory: InventoryService) {}

  @Post("slots")
  createSlot(
    @CurrentUser() user: AuthenticatedUser,
    @Headers("idempotency-key") key: string,
    @Body() dto: CreateSlotDto,
  ) {
    return this.inventory.createSlot(user.id, key, dto);
  }

  @Post("slots/:slotId/block")
  blockSlot(
    @CurrentUser() user: AuthenticatedUser,
    @Param("slotId") slotId: string,
  ) {
    return this.inventory.blockSlot(user.id, slotId);
  }

  @Post("catalog/activities")
  proposeActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ProposeActivityDto,
  ) {
    return this.inventory.proposeActivity(user.id, dto);
  }

  @Post("venues/:venueId/activities/:activityId")
  proposeVenueActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param("venueId") venueId: string,
    @Param("activityId") activityId: string,
  ) {
    return this.inventory.proposeVenueActivity(user.id, venueId, activityId);
  }
}
