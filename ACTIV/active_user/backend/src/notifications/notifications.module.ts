import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module";
import { DeviceController } from "./device.controller";
import { PushNotificationService } from "./push-notification.service";
import { WhatsappChannelService } from "./whatsapp-channel.service";

@Module({
  imports: [AuthModule],
  controllers: [DeviceController],
  providers: [PushNotificationService, WhatsappChannelService],
  exports: [PushNotificationService, WhatsappChannelService],
})
export class NotificationsModule {}
