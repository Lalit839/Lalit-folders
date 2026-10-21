import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { AuthenticatedUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SupportService } from './support.service';

class TicketDto {
  @IsString()
  @MaxLength(160)
  subject!: string;

  @IsString()
  @MaxLength(4000)
  message!: string;

  @IsOptional()
  @IsUUID()
  bookingId?: string;
}

@Controller()
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly support: SupportService) {}

  @Get('notifications')
  getNotifications(@CurrentUser() user: AuthenticatedUser) {
    return this.support.getNotifications(user.id);
  }

  @Patch('notifications/read-all')
  markAllRead(@CurrentUser() user: AuthenticatedUser) {
    return this.support.markAllNotificationsRead(user.id);
  }

  @Patch('notifications/:id/read')
  markRead(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.support.markNotificationRead(user.id, id);
  }

  @Delete('notifications/:id')
  deleteNotification(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.support.deleteNotification(user.id, id);
  }

  @Post('support/tickets')
  createTicket(@CurrentUser() user: AuthenticatedUser, @Body() dto: TicketDto) {
    return this.support.createTicket(user.id, dto);
  }
}
