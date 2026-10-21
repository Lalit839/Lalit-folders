import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { BookingController } from './booking.controller';
import { PartnerBookingController } from './partner-booking.controller';
import { BookingService } from './booking.service';

@Module({
  imports: [AuthModule],
  controllers: [BookingController, PartnerBookingController],
  providers: [BookingService],
  exports: [BookingService],
})
export class BookingModule {}
