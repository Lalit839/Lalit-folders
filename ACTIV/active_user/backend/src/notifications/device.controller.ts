import {
  Body,
  Controller,
  Delete,
  Param,
  Post,
  UseGuards,
} from "@nestjs/common";
import { IsIn, IsString, MaxLength } from "class-validator";
import { AuthenticatedUser, CurrentUser } from "../auth/current-user.decorator";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import { PrismaService } from "../database/prisma.service";

class RegisterDeviceDto {
  @IsIn(["android", "ios", "web"])
  platform!: "android" | "ios" | "web";

  @IsString()
  @MaxLength(512)
  token!: string;
}

@Controller()
@UseGuards(JwtAuthGuard)
export class DeviceController {
  constructor(private readonly prisma: PrismaService) {}

  @Post("devices")
  register(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDeviceDto,
  ) {
    return this.prisma.userDevice.upsert({
      where: { userId_token: { userId: user.id, token: dto.token } },
      create: { userId: user.id, platform: dto.platform, token: dto.token },
      update: { lastSeenAt: new Date() },
      select: { id: true, platform: true, token: true, lastSeenAt: true },
    });
  }

  @Delete("devices/:token")
  async unregister(
    @CurrentUser() user: AuthenticatedUser,
    @Param("token") token: string,
  ) {
    const deleted = await this.prisma.userDevice.deleteMany({
      where: { userId: user.id, token },
    });
    return { removed: deleted.count > 0 };
  }
}
