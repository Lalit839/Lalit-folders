import { Body, Controller, Delete, Get, Ip, Patch, Post, UseGuards } from '@nestjs/common';
import { IsObject, IsOptional, IsString, Matches, Length, MaxLength } from 'class-validator';
import { Prisma } from '@prisma/client';
import { AuthService } from './auth.service';
import { AuthenticatedUser, CurrentUser } from './current-user.decorator';
import { JwtAuthGuard } from './jwt-auth.guard';

class RequestOtpDto {
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/)
  phone!: string;
}

class VerifyOtpDto extends RequestOtpDto {
  @IsString()
  @Length(4, 4)
  @Matches(/^\d{4}$/)
  code!: string;
}

class RefreshTokenDto {
  @IsString()
  refreshToken!: string;
}

class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsString()
  @Matches(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
  @MaxLength(320)
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(5_000_000)
  profilePhoto?: string;

  @IsOptional()
  @IsObject()
  preferences?: Prisma.InputJsonValue;
}

@Controller()
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('auth/otp/request')
  requestOtp(@Body() dto: RequestOtpDto, @Ip() ip: string) {
    return this.auth.requestOtp(dto.phone, ip);
  }

  @Post('auth/otp/verify')
  verifyOtp(@Body() dto: VerifyOtpDto, @Ip() ip: string) {
    return this.auth.verifyOtp(dto.phone, dto.code, ip);
  }

  @Post('auth/token/refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  @Post('auth/logout')
  @UseGuards(JwtAuthGuard)
  logout(@CurrentUser() user: AuthenticatedUser) {
    return this.auth.logout(user.sessionId);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.auth.getProfile(user.id);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  updateProfile(@CurrentUser() user: AuthenticatedUser, @Body() dto: UpdateProfileDto) {
    return this.auth.updateProfile(user.id, dto);
  }

  @Delete('me')
  @UseGuards(JwtAuthGuard)
  requestDeletion(@CurrentUser() user: AuthenticatedUser) {
    return this.auth.requestDeletion(user.id);
  }
}
