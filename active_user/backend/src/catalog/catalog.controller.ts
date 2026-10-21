import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { CatalogService } from './catalog.service';

@Controller()
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('catalog/activities')
  getActivities() {
    return this.catalog.getActivities();
  }

  @Get('catalog/nearby-activities')
  getNearbyActivities(@Query('cityCode') cityCode?: string, @Query('latitude') latitude?: string, @Query('longitude') longitude?: string, @Query('radiusKm') radiusKm?: string, @Query('limit', new ParseIntPipe({ optional: true })) limit = 20) {
    return this.catalog.getNearbyActivities({ cityCode, latitude, longitude, radiusKm, limit });
  }

  @Get('catalog/locations/cities')
  getOperatingCities() {
    return this.catalog.getOperatingCities();
  }

  @Get('catalog/locations/search')
  searchLocations(@Query('q') query?: string) {
    return this.catalog.searchLocations(query);
  }

  @Get('catalog/locations/reverse')
  reverseLocation(@Query('latitude') latitude?: string, @Query('longitude') longitude?: string) {
    return this.catalog.reverseLocation(latitude, longitude);
  }

  @Get('catalog/venues')
  getVenues(@Query('cityCode') cityCode?: string, @Query('activityId') activityId?: string, @Query('type') type?: string, @Query('latitude') latitude?: string, @Query('longitude') longitude?: string, @Query('radiusKm') radiusKm?: string, @Query('page', new ParseIntPipe({ optional: true })) page = 1, @Query('limit', new ParseIntPipe({ optional: true })) limit = 20) {
    return this.catalog.getVenues({ cityCode, activityId, type, latitude, longitude, radiusKm, page, limit });
  }

  @Get('venues/:venueId')
  getVenue(@Param('venueId') venueId: string) {
    return this.catalog.getVenue(venueId);
  }
}
