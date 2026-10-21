import { Controller, Get, Param, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { createReadStream } from 'node:fs';
import { StreamableFile } from '@nestjs/common';
import type { Response } from 'express';
import { MediaService } from './media.service';
import { SkipResponseEnvelope } from '../common/skip-response-envelope.decorator';

const IMMUTABLE_CACHE = 'public, max-age=31536000, immutable';
const SHORT_CACHE = 'public, max-age=86400';
const NO_CACHE = 'no-store';

@ApiTags('media')
@Controller('media')
export class MediaController {
  constructor(private readonly media: MediaService) {}

  @SkipResponseEnvelope()
  @Get('icons/:name')
  getIcon(@Param('name') name: string, @Res({ passthrough: true }) res: Response): StreamableFile {
    const file = this.media.getFile('icons', name);
    res.setHeader('Cache-Control', IMMUTABLE_CACHE);
    res.setHeader('Content-Type', file.contentType);
    res.setHeader('Access-Control-Allow-Origin', '*');
    return new StreamableFile(createReadStream(file.path), { type: file.contentType, disposition: 'inline' });
  }

  @SkipResponseEnvelope()
  @Get('amenities/:name')
  getAmenity(@Param('name') name: string, @Res({ passthrough: true }) res: Response): StreamableFile {
    const file = this.media.getFile('amenities', name);
    res.setHeader('Cache-Control', IMMUTABLE_CACHE);
    res.setHeader('Content-Type', file.contentType);
    res.setHeader('Access-Control-Allow-Origin', '*');
    return new StreamableFile(createReadStream(file.path), { type: file.contentType, disposition: 'inline' });
  }

  @SkipResponseEnvelope()
  @Get('banners/:name')
  getBanner(@Param('name') name: string, @Res({ passthrough: true }) res: Response): StreamableFile {
    const file = this.media.getFile('banners', name);
    res.setHeader('Cache-Control', SHORT_CACHE);
    res.setHeader('Content-Type', file.contentType);
    res.setHeader('Access-Control-Allow-Origin', '*');
    return new StreamableFile(createReadStream(file.path), { type: file.contentType, disposition: 'inline' });
  }

  @SkipResponseEnvelope()
  @Get('venues/:venue/:file')
  getVenue(
    @Param('venue') venue: string,
    @Param('file') file: string,
    @Res({ passthrough: true }) res: Response,
  ): StreamableFile {
    const media = this.media.getVenueFile(venue, file);
    res.setHeader('Cache-Control', SHORT_CACHE);
    res.setHeader('Content-Type', media.contentType);
    res.setHeader('Access-Control-Allow-Origin', '*');
    return new StreamableFile(createReadStream(media.path), { type: media.contentType, disposition: 'inline' });
  }

  @Get('manifest.json')
  getManifest(@Res({ passthrough: true }) res: Response): Record<string, unknown> {
    res.setHeader('Cache-Control', NO_CACHE);
    return this.media.getManifest() as unknown as Record<string, unknown>;
  }
}