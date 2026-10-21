import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { OutboxService } from './outbox.service';

@Module({
  imports: [NotificationsModule],
  providers: [OutboxService],
})
export class OutboxModule {}