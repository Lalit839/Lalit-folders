import { Injectable, NotFoundException } from "@nestjs/common";
import {
  ActivityType,
  ApprovalStatus,
  CatalogueStatus,
  PublishStatus,
} from "@prisma/client";
import { PrismaService } from "../database/prisma.service";
import { MediaService } from "../media/media.service";
import { timePerfStage, timeSyncPerfStage } from "../common/perf-timing";

const ACTIVITY_TYPES: ActivityType[] = Object.values(ActivityType);
const DEFAULT_RADIUS_KM = 30;
const GOOGLE_GEOCODING_URL =
  "https://maps.googleapis.com/maps/api/geocode/json";
const CITY_LABELS: Record<string, { city: string; state: string }> = {
  IND: { city: "Indore", state: "Madhya Pradesh" },
  BOM: { city: "Mumbai", state: "Maharashtra" },
  DEL: { city: "Delhi", state: "Delhi" },
  BLR: { city: "Bengaluru", state: "Karnataka" },
  HYD: { city: "Hyderabad", state: "Telangana" },
  PUN: { city: "Pune", state: "Maharashtra" },
};
const VENUE_LIST_METADATA_KEYS = [
  "address",
  "category",
  "discount",
  "distance",
  "distanceKm",
  "image",
  "imagePath",
  "imageUrls",
  "isAvailable",
  "location",
  "offers",
  "rating",
  "reviewCount",
  "reviews",
  "type",
];

function pickVenueListMetadata(metadata: unknown): Record<string, unknown> {
  if (!metadata || typeof metadata !== "object" || Array.isArray(metadata))
    return {};
  const source = metadata as Record<string, unknown>;
  return VENUE_LIST_METADATA_KEYS.reduce<Record<string, unknown>>(
    (picked, key) => {
      if (source[key] !== undefined) picked[key] = source[key];
      return picked;
    },
    {},
  );
}

function venueDiscountText(
  metadata: Record<string, unknown>,
): string | undefined {
  const direct = discountTextFromValue(metadata.discount);
  if (direct) return direct;

  if (Array.isArray(metadata.offers)) {
    for (const offer of metadata.offers) {
      if (!offer || typeof offer !== "object" || Array.isArray(offer)) continue;
      const source = offer as Record<string, unknown>;
      const text =
        discountTextFromValue(source.discount) ||
        discountTextFromValue(source.title) ||
        discountTextFromValue(source.description);
      if (text) return text;
    }
  }

  return undefined;
}

function discountTextFromValue(value: unknown): string | undefined {
  if (value === null || value === undefined) return undefined;

  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return `${formatNumber(value)}% OFF`;
  }

  if (typeof value !== "string") return undefined;
  const raw = value.trim();
  if (!raw) return undefined;

  const percent = raw.match(/(\d+(?:\.\d+)?)\s*%/);
  if (percent) return `${percent[1]}% OFF`;

  const numeric = Number(raw);
  if (Number.isFinite(numeric) && numeric > 0) {
    return `${formatNumber(numeric)}% OFF`;
  }

  return raw.toUpperCase();
}

function formatNumber(value: number): string {
  return Number.isInteger(value) ? String(value) : String(value);
}

function parseCoordinate(value: string | undefined): number | undefined {
  if (value === undefined || value.trim() === "") return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function parseRadiusKm(value: string | undefined): number {
  if (value === undefined || value.trim() === "") return DEFAULT_RADIUS_KM;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return DEFAULT_RADIUS_KM;
  return Math.min(parsed, 100);
}

function distanceKm(
  from: { latitude: number; longitude: number },
  to: { latitude: unknown; longitude: unknown },
): number | undefined {
  const lat2 = Number(to.latitude);
  const lon2 = Number(to.longitude);
  if (!Number.isFinite(lat2) || !Number.isFinite(lon2)) return undefined;
  const toRadians = (degrees: number) => (degrees * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRadians(lat2 - from.latitude);
  const dLon = toRadians(lon2 - from.longitude);
  const lat1Rad = toRadians(from.latitude);
  const lat2Rad = toRadians(lat2);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1Rad) *
      Math.cos(lat2Rad) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  return 2 * earthRadiusKm * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

@Injectable()
export class CatalogService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly media: MediaService,
  ) {}

  getActivities() {
    return timePerfStage("catalog.activities.db", () =>
      this.prisma.activity.findMany({
        where: { status: CatalogueStatus.PUBLISHED },
        orderBy: { name: "asc" },
        select: { id: true, sportCode: true, name: true, type: true },
      }),
    ).then((items) =>
      timeSyncPerfStage("catalog.activities.serialize", () => ({
        items: items.map((item) => ({
          ...item,
          iconUrl: this.media.activityIconUrl(item.sportCode),
        })),
        pagination: { total: items.length },
      })),
    );
  }

  async getVenues(filters: {
    cityCode?: string;
    activityId?: string;
    type?: string;
    latitude?: string;
    longitude?: string;
    radiusKm?: string;
    page: number;
    limit: number;
  }) {
    const page =
      Number.isFinite(filters.page) && filters.page > 0
        ? Math.floor(filters.page)
        : 1;
    const limit = Number.isFinite(filters.limit)
      ? Math.min(Math.max(Math.floor(filters.limit), 1), 100)
      : 20;
    const type =
      filters.type && ACTIVITY_TYPES.includes(filters.type as ActivityType)
        ? (filters.type as ActivityType)
        : undefined;
    const latitude = parseCoordinate(filters.latitude);
    const longitude = parseCoordinate(filters.longitude);
    const origin =
      latitude !== undefined && longitude !== undefined
        ? { latitude, longitude }
        : undefined;
    const radiusKm = parseRadiusKm(filters.radiusKm);
    const where = {
      status: PublishStatus.PUBLISHED,
      ...(filters.cityCode ? { cityCode: filters.cityCode } : {}),
      ...(filters.activityId
        ? {
            activities: {
              some: {
                activityId: filters.activityId,
                status: ApprovalStatus.APPROVED,
                activity: { status: CatalogueStatus.PUBLISHED },
              },
            },
          }
        : {}),
      ...(type
        ? {
            activities: {
              some: {
                activity: { type, status: CatalogueStatus.PUBLISHED },
                status: ApprovalStatus.APPROVED,
              },
            },
          }
        : {}),
    };
    const [rawItems, total] = await timePerfStage(
      "catalog.venues.db",
      () =>
        this.prisma.$transaction([
          this.prisma.venue.findMany({
            where,
            orderBy: { name: "asc" },
            skip: origin ? undefined : (page - 1) * limit,
            take: origin ? undefined : limit,
            select: {
              id: true,
              name: true,
              cityCode: true,
              latitude: true,
              longitude: true,
              metadata: true,
              partnerProfile: {
                select: {
                  displayName: true,
                  description: true,
                  contactPhoneE164: true,
                  contactEmail: true,
                  addressLine1: true,
                  addressLine2: true,
                  city: true,
                  state: true,
                  postalCode: true,
                  amenities: true,
                  operatingHours: true,
                },
              },
              partnerImages: {
                orderBy: [
                  { isPrimary: "desc" },
                  { sortOrder: "asc" },
                  { createdAt: "asc" },
                ],
                take: 1,
                select: {
                  id: true,
                  url: true,
                  caption: true,
                  sortOrder: true,
                  isPrimary: true,
                },
              },
              activities: {
                where: {
                  status: ApprovalStatus.APPROVED,
                  activity: { status: CatalogueStatus.PUBLISHED },
                },
                select: {
                  activity: {
                    select: {
                      id: true,
                      name: true,
                      sportCode: true,
                      type: true,
                    },
                  },
                },
              },
            },
          }),
          this.prisma.venue.count({ where }),
        ]),
      {
        page,
        limit,
        hasActivityFilter: Boolean(filters.activityId),
        hasCityFilter: Boolean(filters.cityCode),
        hasTypeFilter: Boolean(type),
        hasOrigin: Boolean(origin),
      },
    );
    return timeSyncPerfStage("catalog.venues.serialize", () => {
      const nearbyItems = origin
        ? rawItems.filter((item) => {
            const venueDistance = distanceKm(origin, item);
            return venueDistance !== undefined && venueDistance <= radiusKm;
          })
        : rawItems;
      const orderedItems = origin
        ? [...nearbyItems].sort((a, b) => {
            const aDistance = distanceKm(origin, a) ?? Number.POSITIVE_INFINITY;
            const bDistance = distanceKm(origin, b) ?? Number.POSITIVE_INFINITY;
            return aDistance - bDistance || a.name.localeCompare(b.name);
          })
        : nearbyItems;
      const pagedItems = origin
        ? orderedItems.slice((page - 1) * limit, page * limit)
        : orderedItems;
      const items = pagedItems.map(
        ({ metadata, activities, partnerProfile, partnerImages, ...rest }) => {
          const enriched = pickVenueListMetadata(metadata);
          const discount = venueDiscountText(enriched);
          const imageUrls = (partnerImages ?? []).map((image) => image.url);
          const primaryImage =
            (partnerImages ?? []).find((image) => image.isPrimary) ??
            partnerImages?.[0];
          const computedDistance =
            origin && distanceKm(origin, rest) !== undefined
              ? { distanceKm: Number(distanceKm(origin, rest)!.toFixed(2)) }
              : {};
          const enrichedActivities = (activities ?? []).map(({ activity }) => ({
            activity: {
              ...activity,
              iconUrl: this.media.activityIconUrl(activity.sportCode) ?? "",
            },
          }));
          return {
            ...rest,
            ...enriched,
            name: partnerProfile?.displayName || rest.name,
            displayName: partnerProfile?.displayName || rest.name,
            description: partnerProfile?.description ?? enriched.description,
            address: partnerProfile?.addressLine1 ?? enriched.address,
            location: partnerProfile?.city ?? enriched.location,
            image: primaryImage?.url ?? enriched.image,
            imagePath: primaryImage?.url ?? enriched.imagePath,
            imageUrls: imageUrls.length ? imageUrls : enriched.imageUrls,
            amenities: partnerProfile?.amenities ?? enriched.amenities,
            operatingHours: partnerProfile?.operatingHours,
            contactPhoneE164: partnerProfile?.contactPhoneE164,
            contactEmail: partnerProfile?.contactEmail,
            discount,
            ...computedDistance,
            activities: enrichedActivities,
          };
        },
      );
      return {
        items,
        pagination: {
          page,
          limit,
          total: origin ? orderedItems.length : total,
          totalPages: Math.ceil((origin ? orderedItems.length : total) / limit),
        },
      };
    });
  }

  async getNearbyActivities(filters: {
    cityCode?: string;
    latitude?: string;
    longitude?: string;
    radiusKm?: string;
    limit: number;
  }) {
    const limit =
      Number.isFinite(filters.limit) && filters.limit > 0
        ? Math.min(Math.floor(filters.limit), 100)
        : 20;
    const latitude = parseCoordinate(filters.latitude);
    const longitude = parseCoordinate(filters.longitude);
    const origin =
      latitude !== undefined && longitude !== undefined
        ? { latitude, longitude }
        : undefined;
    const radiusKm = parseRadiusKm(filters.radiusKm);
    const venues = await timePerfStage("catalog.nearbyActivities.db", () =>
      this.prisma.venue.findMany({
        where: {
          status: PublishStatus.PUBLISHED,
          ...(filters.cityCode ? { cityCode: filters.cityCode } : {}),
          activities: {
            some: {
              status: ApprovalStatus.APPROVED,
              activity: { status: CatalogueStatus.PUBLISHED },
            },
          },
        },
        orderBy: { name: "asc" },
        select: {
          id: true,
          name: true,
          latitude: true,
          longitude: true,
          activities: {
            where: {
              status: ApprovalStatus.APPROVED,
              activity: { status: CatalogueStatus.PUBLISHED },
            },
            select: {
              activity: {
                select: {
                  id: true,
                  name: true,
                  sportCode: true,
                  type: true,
                },
              },
            },
          },
        },
      }),
    );
    return timeSyncPerfStage("catalog.nearbyActivities.serialize", () => {
      const nearbyVenues = origin
        ? venues.filter((venue) => {
            const venueDistance = distanceKm(origin, venue);
            return venueDistance !== undefined && venueDistance <= radiusKm;
          })
        : venues;
      const orderedVenues = origin
        ? [...nearbyVenues].sort((a, b) => {
            const aDistance = distanceKm(origin, a) ?? Number.POSITIVE_INFINITY;
            const bDistance = distanceKm(origin, b) ?? Number.POSITIVE_INFINITY;
            return aDistance - bDistance || a.name.localeCompare(b.name);
          })
        : nearbyVenues;
      const bySportCode = new Map<
        string,
        {
          id: string;
          name: string;
          sportCode: string;
          type: ActivityType;
          iconUrl: string;
          nearestVenueId: string;
          nearestVenueName: string;
          distanceKm?: number;
        }
      >();
      for (const venue of orderedVenues) {
        const venueDistance = origin ? distanceKm(origin, venue) : undefined;
        for (const { activity } of venue.activities) {
          if (bySportCode.has(activity.sportCode)) continue;
          bySportCode.set(activity.sportCode, {
            ...activity,
            iconUrl: this.media.activityIconUrl(activity.sportCode) ?? "",
            nearestVenueId: venue.id,
            nearestVenueName: venue.name,
            ...(venueDistance !== undefined
              ? { distanceKm: Number(venueDistance.toFixed(2)) }
              : {}),
          });
        }
      }
      const items = [...bySportCode.values()].slice(0, limit);
      return { items, pagination: { total: bySportCode.size, limit } };
    });
  }

  async getOperatingCities() {
    const venues = await timePerfStage("catalog.operatingCities.db", () =>
      this.prisma.venue.findMany({
        where: { status: PublishStatus.PUBLISHED },
        orderBy: { cityCode: "asc" },
        select: {
          cityCode: true,
          latitude: true,
          longitude: true,
          partnerProfile: { select: { city: true, state: true } },
        },
      }),
    );
    return timeSyncPerfStage("catalog.operatingCities.serialize", () => {
      const byCity = new Map<
        string,
        {
          city: string;
          state: string;
          cityCode: string;
          latitudeTotal: number;
          longitudeTotal: number;
          venueCount: number;
        }
      >();
      for (const venue of venues) {
        const fallback = CITY_LABELS[venue.cityCode] ?? {
          city: venue.cityCode,
          state: "",
        };
        const city = venue.partnerProfile?.city || fallback.city;
        const state = venue.partnerProfile?.state || fallback.state;
        const key = `${city.toLowerCase()}|${state.toLowerCase()}`;
        const existing = byCity.get(key);
        const latitude = Number(venue.latitude);
        const longitude = Number(venue.longitude);
        if (existing) {
          existing.latitudeTotal += latitude;
          existing.longitudeTotal += longitude;
          existing.venueCount += 1;
        } else {
          byCity.set(key, {
            city,
            state,
            cityCode: venue.cityCode,
            latitudeTotal: latitude,
            longitudeTotal: longitude,
            venueCount: 1,
          });
        }
      }
      const cities = [...byCity.values()]
        .map((item) => ({
          city: item.city,
          state: item.state,
          cityCode: item.cityCode,
          latitude: Number((item.latitudeTotal / item.venueCount).toFixed(6)),
          longitude: Number((item.longitudeTotal / item.venueCount).toFixed(6)),
          venueCount: item.venueCount,
        }))
        .sort((a, b) => a.city.localeCompare(b.city));
      return { cities };
    });
  }

  async searchLocations(query?: string) {
    const q = query?.trim();
    if (!q || q.length < 2) return { items: [] };
    const googleItems = await this.searchLocationsWithGoogle(q);
    if (googleItems.length) return { items: googleItems.slice(0, 8) };

    const queries = this.locationQueryVariants(q);
    const seen = new Set<string>();
    const items = this.localLocationFallbacks(q);
    for (const item of items) {
      seen.add(`${item.placeId}|${item.latitude}|${item.longitude}`);
    }
    for (const currentQuery of queries) {
      const rows = await this.fetchLocationSearchRows(currentQuery);
      for (const row of rows) {
        const item = this.locationSuggestion(row);
        if (!item) continue;
        const key = this.locationDedupeKey(item);
        if (seen.has(key)) continue;
        seen.add(key);
        items.push(item);
      }
      if (items.length >= 8) break;
    }
    return { items: items.slice(0, 8) };
  }

  async reverseLocation(latitude?: string, longitude?: string) {
    const lat = parseCoordinate(latitude);
    const lng = parseCoordinate(longitude);
    if (lat === undefined || lng === undefined) return {};
    const googleSuggestion = await this.reverseLocationWithGoogle(lat, lng);
    if (googleSuggestion) return googleSuggestion;

    const params = new URLSearchParams({
      lat: String(lat),
      lon: String(lng),
      format: "jsonv2",
      addressdetails: "1",
      zoom: "18",
    });
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?${params.toString()}`,
      {
        headers: {
          Accept: "application/json",
          "User-Agent": "ACTIV backend reverse location",
        },
      },
    );
    if (!response.ok) return {};
    const data = (await response.json().catch(() => null)) as unknown;
    const suggestion = this.locationSuggestion(data);
    return suggestion ?? {};
  }

  private googleMapsApiKey() {
    const key = process.env.GOOGLE_MAPS_API_KEY?.trim();
    return key || undefined;
  }

  private async searchLocationsWithGoogle(query: string) {
    const key = this.googleMapsApiKey();
    if (!key) return [];
    const variants = this.locationQueryVariants(query);
    const seen = new Set<string>();
    const items = [...this.localLocationFallbacks(query)];
    for (const item of items) {
      seen.add(this.locationDedupeKey(item));
    }

    for (const currentQuery of variants) {
      const params = new URLSearchParams({
        address: currentQuery,
        components: "country:IN",
        region: "in",
        key,
      });
      const response = await fetch(
        `${GOOGLE_GEOCODING_URL}?${params.toString()}`,
        {
          headers: { Accept: "application/json" },
        },
      ).catch(() => null);
      if (!response?.ok) continue;
      const data = (await response.json().catch(() => null)) as unknown;
      const results = this.googleResults(data);
      for (const result of results) {
        const item = this.googleLocationSuggestion(result);
        if (!item) continue;
        const dedupeKey = this.locationDedupeKey(item);
        if (seen.has(dedupeKey)) continue;
        seen.add(dedupeKey);
        items.push(item);
      }
      if (items.length >= 8) break;
    }
    return items;
  }

  private async reverseLocationWithGoogle(latitude: number, longitude: number) {
    const key = this.googleMapsApiKey();
    if (!key) return null;
    const params = new URLSearchParams({
      latlng: `${latitude},${longitude}`,
      key,
    });
    const response = await fetch(
      `${GOOGLE_GEOCODING_URL}?${params.toString()}`,
      {
        headers: { Accept: "application/json" },
      },
    ).catch(() => null);
    if (!response?.ok) return null;
    const data = (await response.json().catch(() => null)) as unknown;
    const result = this.googleResults(data)[0];
    return this.googleLocationSuggestion(result);
  }

  private googleResults(data: unknown) {
    if (!data || typeof data !== "object" || Array.isArray(data)) return [];
    const source = data as Record<string, unknown>;
    return Array.isArray(source.results) ? source.results : [];
  }

  private googleLocationSuggestion(result: unknown) {
    if (!result || typeof result !== "object" || Array.isArray(result))
      return null;
    const source = result as Record<string, unknown>;
    const geometry =
      source.geometry &&
      typeof source.geometry === "object" &&
      !Array.isArray(source.geometry)
        ? (source.geometry as Record<string, unknown>)
        : {};
    const location =
      geometry.location &&
      typeof geometry.location === "object" &&
      !Array.isArray(geometry.location)
        ? (geometry.location as Record<string, unknown>)
        : {};
    const latitude = Number(location.lat);
    const longitude = Number(location.lng);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

    const components = this.googleAddressComponents(source.address_components);
    const city = this.firstNonEmpty(
      components.locality,
      components.postal_town,
      components.administrative_area_level_3,
      components.administrative_area_level_2,
    );
    const locality = this.firstNonEmpty(
      components.sublocality_level_1,
      components.sublocality,
      components.neighborhood,
      components.route,
      city,
    );
    const state = this.firstNonEmpty(components.administrative_area_level_1);
    const country = this.firstNonEmpty(components.country);
    const displayName =
      typeof source.formatted_address === "string"
        ? source.formatted_address
        : [locality, city, state, country].filter(Boolean).join(", ");
    const mainText = this.firstNonEmpty(
      locality,
      city,
      displayName.split(",")[0],
    );
    if (!mainText) return null;

    return {
      placeId: String(source.place_id ?? ""),
      mainText,
      secondaryText: [city && city !== mainText ? city : "", state, country]
        .filter(Boolean)
        .join(", "),
      latitude,
      longitude,
      displayName,
      city: this.firstNonEmpty(city, state),
      locality,
      district: this.firstNonEmpty(
        components.administrative_area_level_3,
        components.administrative_area_level_2,
      ),
      state,
      country,
      countryCode: this.firstNonEmpty(components.countryCode).toUpperCase(),
      postalCode: this.firstNonEmpty(components.postal_code),
    };
  }

  private googleAddressComponents(value: unknown) {
    const components: Record<string, string> = {};
    if (!Array.isArray(value)) return components;
    for (const item of value) {
      if (!item || typeof item !== "object" || Array.isArray(item)) continue;
      const component = item as Record<string, unknown>;
      const longName =
        typeof component.long_name === "string" ? component.long_name : "";
      const shortName =
        typeof component.short_name === "string" ? component.short_name : "";
      const types = Array.isArray(component.types) ? component.types : [];
      for (const type of types) {
        if (typeof type !== "string") continue;
        if (!components[type] && longName) components[type] = longName;
        if (type === "country" && shortName) components.countryCode = shortName;
      }
    }
    return components;
  }

  private firstNonEmpty(...values: unknown[]) {
    for (const value of values) {
      const text = typeof value === "string" ? value.trim() : "";
      if (text) return text;
    }
    return "";
  }

  private async fetchLocationSearchRows(query: string) {
    const params = new URLSearchParams({
      q: query,
      format: "jsonv2",
      addressdetails: "1",
      countrycodes: "in",
      limit: "8",
      dedupe: "1",
    });
    const response = await fetch(
      `https://nominatim.openstreetmap.org/search?${params.toString()}`,
      {
        headers: {
          Accept: "application/json",
          "User-Agent": "ACTIV backend location search",
        },
      },
    );
    if (!response.ok) return [];
    const data = (await response.json().catch(() => [])) as unknown;
    return Array.isArray(data) ? data : [];
  }

  private locationQueryVariants(query: string) {
    const variants = new Set<string>();
    const add = (value: string) => {
      const trimmed = value.trim();
      if (trimmed.length >= 2) variants.add(trimmed);
    };
    add(query);
    add(`${query}, India`);
    const lower = query.toLowerCase();
    if (!lower.includes("indore")) {
      add(`${query}, Indore, Madhya Pradesh, India`);
    }
    if (lower.includes("mahalaxmi")) {
      const alt = query.replace(/mahalaxmi/gi, "Mahalakshmi");
      add(alt);
      add(`${alt}, Indore, Madhya Pradesh, India`);
    }
    if (lower.includes("mahalakshmi")) {
      const alt = query.replace(/mahalakshmi/gi, "Mahalaxmi");
      add(alt);
      add(`${alt}, Indore, Madhya Pradesh, India`);
    }
    return [...variants];
  }

  private localLocationFallbacks(query: string) {
    const normalized = query.toLowerCase().replace(/\s+/g, " ").trim();
    const items = [];
    if (
      normalized.includes("mahalaxmi") ||
      normalized.includes("mahalakshmi")
    ) {
      items.push({
        placeId: "local-mahalaxmi-nagar-indore",
        mainText: "Mahalaxmi Nagar",
        secondaryText: "Indore, Madhya Pradesh, India",
        latitude: 22.7533,
        longitude: 75.9034,
        displayName: "Mahalaxmi Nagar, Indore, Madhya Pradesh, India",
        city: "Indore",
        locality: "Mahalaxmi Nagar",
        district: "Indore",
        state: "Madhya Pradesh",
        country: "India",
        countryCode: "IN",
        postalCode: "",
      });
    }
    return items;
  }

  private locationDedupeKey(item: {
    mainText: string;
    secondaryText: string;
    latitude: number;
    longitude: number;
  }) {
    const normalizedText = `${item.mainText}|${item.secondaryText}`
      .toLowerCase()
      .replace(/[^a-z0-9|]+/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    const latBucket = Number.isFinite(item.latitude)
      ? Math.round(item.latitude * 100) / 100
      : "";
    const lngBucket = Number.isFinite(item.longitude)
      ? Math.round(item.longitude * 100) / 100
      : "";
    return `${normalizedText}|${latBucket}|${lngBucket}`;
  }

  async getVenue(venueId: string) {
    const now = new Date();
    const [
      venue,
      profileRows,
      partnerImages,
      venueAmenities,
      partnerServices,
      serviceAmenities,
      availability,
      todaySlots,
    ] = await timePerfStage("catalog.venue.db", () =>
      Promise.all([
        this.prisma.venue.findFirst({
          where: { id: venueId, status: PublishStatus.PUBLISHED },
          select: {
            id: true,
            name: true,
            cityCode: true,
            latitude: true,
            longitude: true,
            policyVersion: true,
            metadata: true,
            activities: {
              where: {
                status: ApprovalStatus.APPROVED,
                activity: { status: CatalogueStatus.PUBLISHED },
              },
              select: {
                activity: {
                  select: {
                    id: true,
                    name: true,
                    sportCode: true,
                    type: true,
                  },
                },
              },
            },
            facilities: {
              select: {
                id: true,
                name: true,
                capacity: true,
                activityId: true,
                venueId: true,
              },
            },
          },
        }),
        this.prisma.$queryRaw<
          Array<{
            display_name: string | null;
            description: string | null;
            contact_phone_e164: string | null;
            contact_email: string | null;
            address_line_1: string | null;
            address_line_2: string | null;
            city: string | null;
            state: string | null;
            postal_code: string | null;
            location_url: string | null;
            rules: unknown;
            opening_time: string | null;
            closing_time: string | null;
            operating_hours: unknown;
          }>
        >`
            select
              display_name,
              description,
              contact_phone_e164,
              contact_email,
              address_line_1,
              address_line_2,
              city,
              state,
              postal_code,
              location_url,
              rules,
              opening_time::text as opening_time,
              closing_time::text as closing_time,
              operating_hours
            from partner_venue_profiles
            where venue_id = ${venueId}::uuid
            limit 1
          `,
        this.prisma.partnerVenueImage.findMany({
          where: { venueId },
          orderBy: [
            { isPrimary: "desc" },
            { sortOrder: "asc" },
            { createdAt: "asc" },
          ],
          select: {
            id: true,
            url: true,
            caption: true,
            sortOrder: true,
            isPrimary: true,
          },
        }),
        this.prisma.$queryRaw<
          Array<{
            title: string;
            sort_order: number | null;
          }>
        >`
            select
              title,
              sort_order
            from partner_venue_amenities
            where venue_id = ${venueId}::uuid
            order by sort_order asc, title asc
          `,
        this.prisma.$queryRaw<
          Array<{
            id: string;
            title: string;
            description: string | null;
            service_category_id: string;
            category_name: string | null;
            category_slug: string | null;
            facility_id: string | null;
            activity_id: string | null;
            capacity: number | null;
            status: string;
            is_active: boolean;
          }>
        >`
            select
              pvs.id::text,
              pvs.title,
              pvs.description,
              pvs.service_category_id::text,
              psc.name as category_name,
              psc.slug as category_slug,
              pvs.facility_id::text,
              coalesce(f.activity_id, activity.id)::text as activity_id,
              coalesce(pvs.capacity, f.capacity) as capacity,
              pvs.status::text as status,
              pvs.is_active
            from partner_venue_services pvs
            join partner_service_categories psc on psc.id = pvs.service_category_id
            left join facilities f on f.id = pvs.facility_id
            left join lateral (
              select a.id
              from activities a
              where a.status = 'PUBLISHED'::"CatalogueStatus"
                and (
                  lower(a.sport_code) = lower(psc.slug)
                  or lower(a.name) = lower(psc.name)
                  or lower(a.name) = lower(pvs.title)
                  or lower(a.sport_code) = lower(regexp_replace(pvs.title, '[^a-zA-Z0-9]+', '_', 'g'))
                )
              order by
                case
                  when lower(a.sport_code) = lower(psc.slug) then 0
                  when lower(a.name) = lower(psc.name) then 1
                  when lower(a.name) = lower(pvs.title) then 2
                  else 3
                end,
                a.name asc
              limit 1
            ) activity on true
            where pvs.venue_id = ${venueId}::uuid
            order by pvs.created_at asc
          `,
        this.prisma.$queryRaw<
          Array<{
            venue_service_id: string;
            title: string;
            sort_order: number | null;
          }>
        >`
            select
              venue_service_id::text,
              title,
              sort_order
            from partner_service_amenities
            where venue_service_id in (
              select id from partner_venue_services where venue_id = ${venueId}::uuid
            )
            order by venue_service_id asc, sort_order asc, title asc
          `,
        this.prisma.$queryRaw<
          Array<{
            day: string;
            open_time: string;
            close_time: string;
            capacity: number;
            price_paise: bigint;
            discounted_price_paise: bigint | null;
            service_category_id: string;
            sort_order: number | null;
          }>
        >`
            select
              day,
              open_time,
              close_time,
              capacity,
              price_paise,
              discounted_price_paise,
              service_category_id::text,
              sort_order
            from partner_venue_availability
            where venue_id = ${venueId}::uuid
            order by sort_order asc, day asc, open_time asc
          `,
        this.prisma.slot.findMany({
          where: {
            status: "AVAILABLE",
            capacity: { gt: 0 },
            bookedQuantity: { lt: this.prisma.slot.fields.capacity },
            startsAt: {
              gte: new Date(now.getFullYear(), now.getMonth(), now.getDate()),
              lt: new Date(
                now.getFullYear(),
                now.getMonth(),
                now.getDate() + 1,
              ),
            },
            facility: { venueId },
          },
          orderBy: { startsAt: "asc" },
          select: {
            id: true,
            facilityId: true,
            startsAt: true,
            endsAt: true,
            capacity: true,
            bookedQuantity: true,
            status: true,
            pricePaise: true,
          },
        }),
      ]),
    );
    if (!venue) throw new NotFoundException("Venue not found");
    return timeSyncPerfStage("catalog.venue.serialize", () => {
      const { metadata, activities, facilities, ...rest } = venue;
      const enriched = metadata
        ? { ...(metadata as Record<string, unknown>) }
        : {};
      this.removePrivateVenueMetadata(enriched);
      const profile = profileRows[0];
      const sortedImages = [...partnerImages].sort((a, b) => {
        if (a.isPrimary !== b.isPrimary) return a.isPrimary ? -1 : 1;
        return a.sortOrder - b.sortOrder;
      });
      const imageUrls = sortedImages.map((image) => image.url);
      const primaryImage =
        sortedImages.find((image) => image.isPrimary) ?? sortedImages[0];
      const partnerAmenityItems = venueAmenities.map((amenity) => ({
        id: this.publicCompositeId(
          "venue-amenity",
          venueId,
          amenity.sort_order,
          amenity.title,
        ),
        name: amenity.title,
        iconAsset: "",
        iconUrl: this.media.amenityIconUrl(amenity.title),
        sortOrder: amenity.sort_order ?? 0,
      }));
      const fallbackAmenities = this.amenitiesFromMetadata(enriched.amenities);
      const amenities = partnerAmenityItems.length
        ? partnerAmenityItems
        : fallbackAmenities;
      const normalizedFacilities = facilities.map((facility) => ({
        id: facility.id,
        venueId: facility.venueId,
        activityId: facility.activityId,
        name: facility.name,
        capacity: facility.capacity,
      }));
      const serviceAmenitiesByService = new Map<string, unknown[]>();
      for (const amenity of serviceAmenities) {
        const items =
          serviceAmenitiesByService.get(amenity.venue_service_id) ?? [];
        items.push({
          id: this.publicCompositeId(
            "service-amenity",
            amenity.venue_service_id,
            amenity.sort_order,
            amenity.title,
          ),
          name: amenity.title,
          iconAsset: "",
          iconUrl: this.media.amenityIconUrl(amenity.title),
          sortOrder: amenity.sort_order ?? 0,
        });
        serviceAmenitiesByService.set(amenity.venue_service_id, items);
      }
      const services = partnerServices
        .filter((service) => service.status === "APPROVED" && service.is_active)
        .map((service) => ({
          id: service.id,
          title: service.title,
          description: service.description,
          categoryId: service.service_category_id,
          categoryName: service.category_name,
          categorySlug: service.category_slug,
          facilityId: service.facility_id,
          activityId: service.activity_id,
          capacity: service.capacity ?? 0,
          status: service.status,
          isActive: service.is_active,
          amenities: serviceAmenitiesByService.get(service.id) ?? [],
        }));
      const facilitiesByActivity = new Map<
        string,
        typeof normalizedFacilities
      >();
      for (const facility of normalizedFacilities) {
        const items = facilitiesByActivity.get(facility.activityId) ?? [];
        items.push(facility);
        facilitiesByActivity.set(facility.activityId, items);
      }
      const servicesByActivity = new Map<string, typeof services>();
      for (const service of services) {
        if (!service.activityId) continue;
        const items = servicesByActivity.get(service.activityId) ?? [];
        items.push(service);
        servicesByActivity.set(service.activityId, items);
      }
      const enrichedActivities = (activities ?? []).map(({ activity }) => ({
        id: activity.id,
        name: activity.name,
        sportCode: activity.sportCode,
        type: activity.type,
        iconUrl: this.media.activityIconUrl(activity.sportCode),
        facilities: facilitiesByActivity.get(activity.id) ?? [],
        services: servicesByActivity.get(activity.id) ?? [],
      }));
      const availabilityItems = availability.map((item) => ({
        day: item.day,
        openTime: item.open_time,
        closeTime: item.close_time,
        capacity: item.capacity,
        pricePaise: item.price_paise.toString(),
        discountedPricePaise: item.discounted_price_paise?.toString() ?? null,
        serviceCategoryId: item.service_category_id,
        sortOrder: item.sort_order ?? 0,
      }));
      const operatingHours =
        this.nonEmptyObject(profile?.operating_hours) ??
        this.operatingHoursFromAvailability(availabilityItems) ??
        enriched.operatingHours;
      const rules = this.rulesFromValue(profile?.rules ?? enriched.rules);
      return {
        ...rest,
        ...enriched,
        name: profile?.display_name || rest.name,
        displayName: profile?.display_name || rest.name,
        description: profile?.description ?? enriched.description,
        contactPhoneE164: profile?.contact_phone_e164,
        contactEmail: profile?.contact_email,
        addressLine1: profile?.address_line_1,
        addressLine2: profile?.address_line_2,
        address: this.firstNonEmpty(profile?.address_line_1, enriched.address),
        city: profile?.city ?? rest.cityCode,
        state: profile?.state,
        postalCode: profile?.postal_code,
        latitude: rest.latitude,
        longitude: rest.longitude,
        locationUrl: profile?.location_url,
        rules,
        openingTime: profile?.opening_time,
        closingTime: profile?.closing_time,
        amenities,
        services,
        facilities: normalizedFacilities,
        availability: availabilityItems,
        operatingHours,
        images: sortedImages,
        image: primaryImage?.url ?? enriched.image,
        imagePath: primaryImage?.url ?? enriched.imagePath,
        imageUrls: imageUrls.length ? imageUrls : enriched.imageUrls,
        todaySlots: todaySlots
          .filter((slot) => slot.capacity > slot.bookedQuantity)
          .map((slot) => ({
            slotId: slot.id,
            facilityId: slot.facilityId,
            startsAt: slot.startsAt,
            endsAt: slot.endsAt,
            availableQuantity: slot.capacity - slot.bookedQuantity,
            pricePaise: slot.pricePaise.toString(),
            currency: "INR",
          })),
        activities: enrichedActivities,
      };
    });
  }

  private amenitiesFromMetadata(value: unknown) {
    if (!Array.isArray(value)) return [];
    return value
      .map((amenity) => {
        if (typeof amenity === "string" && amenity.trim()) {
          return {
            name: amenity.trim(),
            iconAsset: "",
            iconUrl: this.media.amenityIconUrl(amenity),
          };
        }
        if (!amenity || typeof amenity !== "object" || Array.isArray(amenity))
          return null;
        const source = amenity as Record<string, unknown>;
        const name = this.firstNonEmpty(
          source.name,
          source.label,
          source.title,
        );
        if (!name) return null;
        return {
          ...source,
          name,
          iconUrl:
            this.firstNonEmpty(source.iconUrl) ||
            this.media.amenityIconUrl(name),
        };
      })
      .filter(Boolean);
  }

  private removePrivateVenueMetadata(metadata: Record<string, unknown>) {
    for (const key of [
      "aadhaarCardUrl",
      "aadhaarName",
      "aadhaarNumber",
      "approvedAt",
      "approvedBy",
      "commission",
      "electronicSignature",
      "legalInfo",
      "ownerPhone",
      "panCardUrl",
      "panNumber",
      "rejectionReason",
      "reviewStatus",
      "submittedAt",
    ]) {
      delete metadata[key];
    }
  }

  private publicCompositeId(...parts: unknown[]) {
    return parts
      .map((part) =>
        String(part ?? "")
          .trim()
          .toLowerCase(),
      )
      .filter(Boolean)
      .join(":")
      .replace(/[^a-z0-9:]+/g, "-")
      .replace(/-+/g, "-");
  }

  private rulesFromValue(value: unknown) {
    if (Array.isArray(value)) {
      return value
        .map((item) => (typeof item === "string" ? item.trim() : ""))
        .filter(Boolean);
    }
    if (typeof value === "string" && value.trim()) return [value.trim()];
    return [];
  }

  private nonEmptyObject(value: unknown) {
    if (!value || typeof value !== "object" || Array.isArray(value))
      return undefined;
    return Object.keys(value).length ? value : undefined;
  }

  private operatingHoursFromAvailability(
    availability: Array<{ day: string; openTime: string; closeTime: string }>,
  ) {
    if (!availability.length) return undefined;
    const grouped = new Map<string, Set<string>>();
    for (const item of availability) {
      const day = item.day?.trim();
      if (!day || !item.openTime || !item.closeTime) continue;
      const ranges = grouped.get(day) ?? new Set<string>();
      ranges.add(`${item.openTime} - ${item.closeTime}`);
      grouped.set(day, ranges);
    }
    if (!grouped.size) return undefined;
    return [...grouped.entries()].reduce<Record<string, string[]>>(
      (hours, [day, ranges]) => {
        hours[day] = [...ranges].sort();
        return hours;
      },
      {},
    );
  }

  private locationSuggestion(row: unknown) {
    if (!row || typeof row !== "object" || Array.isArray(row)) return null;
    const source = row as Record<string, unknown>;
    const address =
      source.address &&
      typeof source.address === "object" &&
      !Array.isArray(source.address)
        ? (source.address as Record<string, unknown>)
        : {};
    const first = (...values: unknown[]) => {
      for (const value of values) {
        const text = typeof value === "string" ? value.trim() : "";
        if (text) return text;
      }
      return "";
    };
    const mainText = first(
      address.neighbourhood,
      address.suburb,
      address.city,
      address.town,
      address.village,
      address.county,
      source.name,
      typeof source.display_name === "string"
        ? source.display_name.split(",")[0]
        : "",
    );
    if (!mainText) return null;
    const city = first(
      address.city,
      address.town,
      address.village,
      address.county,
    );
    const state = first(address.state);
    const country = first(address.country);
    const secondaryText = [city !== mainText ? city : "", state, country]
      .filter(Boolean)
      .join(", ");
    return {
      placeId: String(source.place_id ?? source.osm_id ?? ""),
      mainText,
      secondaryText,
      latitude: Number(source.lat),
      longitude: Number(source.lon),
      displayName: String(
        source.display_name ??
          [mainText, secondaryText].filter(Boolean).join(", "),
      ),
      city: first(
        address.city,
        address.town,
        address.village,
        address.county,
        address.state,
      ),
      locality: first(
        address.neighbourhood,
        address.suburb,
        address.city_district,
        city,
      ),
      district: first(address.county),
      state,
      country,
      countryCode: first(address.country_code).toUpperCase(),
      postalCode: first(address.postcode),
    };
  }
}
