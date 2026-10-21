import { Module } from '@nestjs/common';
import { WebsiteLegacyController } from './website-legacy.controller';
import { WebsiteController } from './website.controller';
import { WebsiteService } from './website.service';

@Module({
  controllers: [WebsiteController, WebsiteLegacyController],
  providers: [WebsiteService],
})
export class WebsiteModule {}
