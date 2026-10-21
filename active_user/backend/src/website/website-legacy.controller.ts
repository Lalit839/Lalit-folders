import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { IsEmail, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { SkipResponseEnvelope } from '../common/skip-response-envelope.decorator';
import { WebsiteService } from './website.service';
import { WebsiteSocialLinks } from './website.types';

class LegacyWebsiteFaqDto {
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  category!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(300)
  question!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(3000)
  answer!: string;
}

class LegacyContactDto {
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  fullName!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @IsOptional()
  @MaxLength(40)
  phone?: string;

  @IsString()
  @MinLength(1)
  @MaxLength(5000)
  message!: string;
}

class LegacySocialLinksDto implements WebsiteSocialLinks {
  @IsString()
  instagram!: string;

  @IsString()
  linkedin!: string;

  @IsString()
  facebook!: string;

  @IsString()
  youtube!: string;

  @IsString()
  x!: string;
}

@Controller('api')
@SkipResponseEnvelope()
export class WebsiteLegacyController {
  constructor(private readonly website: WebsiteService) {}

  @Get('admin/profile')
  getProfile() {
    return this.website.getProfile();
  }

  @Get('contacts')
  listContacts() {
    return this.website.listContacts();
  }

  @Post('contacts')
  createContact(@Body() dto: LegacyContactDto) {
    return this.website.createContact(dto);
  }

  @Get('faqs')
  listFaqs() {
    return this.website.listFaqs();
  }

  @Post('faqs')
  createFaq(@Body() dto: LegacyWebsiteFaqDto) {
    return this.website.createFaq(dto);
  }

  @Put('faqs/:id')
  updateFaq(@Param('id') id: string, @Body() dto: LegacyWebsiteFaqDto) {
    return this.website.updateFaq(id, dto);
  }

  @Delete('faqs/:id')
  deleteFaq(@Param('id') id: string) {
    return this.website.deleteFaq(id);
  }

  @Get('social-links')
  getSocialLinks() {
    return this.website.getSocialLinks();
  }

  @Put('social-links')
  updateSocialLinks(@Body() dto: LegacySocialLinksDto) {
    return this.website.updateSocialLinks(dto);
  }
}
