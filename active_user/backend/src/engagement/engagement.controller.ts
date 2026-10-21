import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query, UseGuards } from '@nestjs/common';
import { IsDateString, IsInt, IsString, Max, MaxLength, Min } from 'class-validator';
import { AuthenticatedUser, CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { EngagementService } from './engagement.service';

class ReviewDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsString()
  @MaxLength(2000)
  body!: string;
}

class ShareCardDto {
  @IsDateString()
  from!: string;

  @IsDateString()
  to!: string;
}

@Controller()
@UseGuards(JwtAuthGuard)
export class EngagementController {
  constructor(private readonly engagement: EngagementService) {}

  @Get('me/saved-venues')
  getSaved(@CurrentUser() user: AuthenticatedUser) {
    return this.engagement.getSavedVenues(user.id);
  }

  @Put('me/saved-venues/:venueId')
  save(@CurrentUser() user: AuthenticatedUser, @Param('venueId') venueId: string) {
    return this.engagement.saveVenue(user.id, venueId);
  }

  @Delete('me/saved-venues/:venueId')
  unsave(@CurrentUser() user: AuthenticatedUser, @Param('venueId') venueId: string) {
    return this.engagement.removeSavedVenue(user.id, venueId);
  }

  @Post('bookings/:bookingId/review')
  review(@CurrentUser() user: AuthenticatedUser, @Param('bookingId') bookingId: string, @Body() dto: ReviewDto) {
    return this.engagement.createReview(user.id, bookingId, dto.rating, dto.body);
  }

  @Patch('reviews/:reviewId')
  editReview(@CurrentUser() user: AuthenticatedUser, @Param('reviewId') reviewId: string, @Body() dto: ReviewDto) {
    return this.engagement.editReview(user.id, reviewId, dto.rating, dto.body);
  }

  @Get('calendar')
  calendar(@CurrentUser() user: AuthenticatedUser, @Query('from') from: string, @Query('to') to: string) {
    return this.engagement.getCalendar(user.id, from, to);
  }

  @Post('share-cards')
  shareCard(@CurrentUser() user: AuthenticatedUser, @Body() dto: ShareCardDto) {
    return this.engagement.createShareCard(user.id, dto.from, dto.to);
  }
}
