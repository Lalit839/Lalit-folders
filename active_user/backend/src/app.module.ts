import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR, APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { ConfigModule } from '@nestjs/config';
import { ApiEnvelopeInterceptor } from './common/api-envelope.interceptor';
import { HealthController } from './health/health.controller';
import { CronController } from './cron/cron.controller';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { BookingModule } from './booking/booking.module';
import { PaymentsModule } from './payments/payments.module';
import { CatalogModule } from './catalog/catalog.module';
import { AdminModule } from './admin/admin.module';
import { InventoryModule } from './inventory/inventory.module';
import { EngagementModule } from './engagement/engagement.module';
import { SupportModule } from './support/support.module';
import { OutboxModule } from './outbox/outbox.module';
import { ContentModule } from './content/content.module';
import { SecurityModule } from './security/security.module';
import { NotificationsModule } from './notifications/notifications.module';
import { KeepAliveModule } from './keepalive/keep-alive.module';
import { MediaModule } from './media/media.module';
import { WebsiteModule } from './website/website.module';
import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      ignoreEnvFile: process.env.NODE_ENV === 'production',
      validate: (config) => {
        const required = ['DATABASE_URL', 'JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET'];
        if (config.NODE_ENV === 'production') {
          for (const key of required) if (!config[key]) throw new Error(`${key} is required in production`);
          if (!config.CORS_ORIGINS) throw new Error('CORS_ORIGINS is required in production');
          if (config.DEMO_PAYMENT !== 'true') {
            for (const key of ['RAZORPAY_KEY_ID', 'RAZORPAY_KEY_SECRET', 'RAZORPAY_WEBHOOK_SECRET'])
              if (!config[key]) throw new Error(`${key} is required in production when DEMO_PAYMENT is not true`);
          }
          if (config.DEMO_OTP !== 'true') {
            for (const key of ['OTP_PROVIDER_API_KEY', 'OTP_PROVIDER_TEMPLATE_ID'])
              if (!config[key]) throw new Error(`${key} is required in production when DEMO_OTP is not true`);
          }
          for (const key of ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET'])
            if (!config[key]) throw new Error(`${key} is required in production for venue image uploads`);
        }
        return config;
      },
    }),
    ScheduleModule.forRoot(),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 60 }]),
    DatabaseModule,
    AuthModule,
    BookingModule,
    PaymentsModule,
    CatalogModule,
    AdminModule,
    InventoryModule,
    EngagementModule,
    SupportModule,
    OutboxModule,
    ContentModule,
    SecurityModule,
    NotificationsModule,
    KeepAliveModule,
    MediaModule,
    WebsiteModule,
  ],
  controllers: [HealthController, CronController],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: ApiEnvelopeInterceptor },
  ],
})
export class AppModule {}
