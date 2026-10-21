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
                orderBy: [{ isPrimary: "desc" }, { sortOrder: "asc" }, { createdAt: "asc" }],
                take: 1,
                select: { id: true, url: true, caption: true, sortOrder: true, isPrimary: true },
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
            const aDistance =
              distanceKm(origin, a) ?? Number.POSITIVE_INFINITY;
            const bDistance =
              distanceKm(origin, b) ?? Number.POSITIVE_INFINITY;
            return aDistance - bDistance || a.name.localeCompare(b.name);
          })
        : nearbyItems;
      const pagedItems = origin
        ? orderedItems.slice((page - 1) * limit, page * limit)
        : orderedItems;
      const items = pagedItems.map(({ metadata, activities, partnerProfile, partnerImages, ...rest }) => {
        const enriched = pickVenueListMetadata(metadata);
        const imageUrls = (partnerImages ?? []).map((image) => image.url);
        const primaryImage = (partnerImages ?? []).find((image) => image.isPrimary) ?? partnerImages?.[0];
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
          ...computedDistance,
          activities: enrichedActivities,
        };
      });
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
            const aDistance =
              distanceKm(origin, a) ?? Number.POSITIVE_INFINITY;
            const bDistance =
              distanceKm(origin, b) ?? Number.POSITIVE_INFINITY;
            return aDistance - bDistance || a.name.localeCompare(b.name);
          })
        : nearbyVenues;
      const bySportCode = new Map<string, {
        id: string;
        name: string;
        sportCode: string;
        type: ActivityType;
        iconUrl: string;
        nearestVenueId: string;
        nearestVenueName: string;
        distanceKm?: number;
      }>();
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
    const venue = await timePerfStage("catalog.venue.db", () =>
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
            orderBy: [{ isPrimary: "desc" }, { sortOrder: "asc" }, { createdAt: "asc" }],
            select: { id: true, url: true, caption: true, sortOrder: true, isPrimary: true },
          },
          activities: {
            where: {
              status: ApprovalStatus.APPROVED,
              activity: { status: CatalogueStatus.PUBLISHED },
            },
            select: {
              activity: {
                select: { id: true, name: true, sportCode: true, type: true },
              },
            },
          },
          facilities: {
            where: {
              slots: {
                some: {
                  status: "AVAILABLE",
                  startsAt: { gt: now },
                },
              },
            },
            select: { id: true, name: true, capacity: true, activityId: true },
          },
        },
      }),
    );
    if (!venue) throw new NotFoundException("Venue not found");
    return timeSyncPerfStage("catalog.venue.serialize", () => {
      const { metadata, activities, partnerProfile, partnerImages, ...rest } = venue;
      const enriched = metadata
        ? { ...(metadata as Record<string, unknown>) }
        : {};
      const imageUrls = (partnerImages ?? []).map((image) => image.url);
      const primaryImage = (partnerImages ?? []).find((image) => image.isPrimary) ?? partnerImages?.[0];
      if (Array.isArray(enriched.amenities)) {
        enriched.amenities = enriched.amenities.map((amenity) => {
          const a = amenity as { name?: string; iconAsset?: string };
          return {
            ...a,
            iconUrl: this.media.amenityIconUrl(a.name ?? a.iconAsset ?? ""),
          };
        });
      }
      const bookableActivityIds = new Set(
        (rest.facilities ?? []).map((facility) => facility.activityId),
      );
      const enrichedActivities = (activities ?? [])
        .filter(({ activity }) => bookableActivityIds.has(activity.id))
        .map(({ activity }) => ({
          activity: {
            ...activity,
            iconUrl: this.media.activityIconUrl(activity.sportCode),
          },
        }));
      return {
        ...rest,
        ...enriched,
        name: partnerProfile?.displayName || rest.name,
        displayName: partnerProfile?.displayName || rest.name,
        description: partnerProfile?.description ?? enriched.description,
        contactPhoneE164: partnerProfile?.contactPhoneE164,
        contactEmail: partnerProfile?.contactEmail,
        addressLine1: partnerProfile?.addressLine1,
        addressLine2: partnerProfile?.addressLine2,
        city: partnerProfile?.city ?? rest.cityCode,
        state: partnerProfile?.state,
        postalCode: partnerProfile?.postalCode,
        amenities: partnerProfile?.amenities ?? enriched.amenities,
        operatingHours: partnerProfile?.operatingHours,
        images: partnerImages,
        image: primaryImage?.url ?? enriched.image,
        imagePath: primaryImage?.url ?? enriched.imagePath,
        imageUrls: imageUrls.length ? imageUrls : enriched.imageUrls,
        activities: enrichedActivities,
      };
    });
  }

  private locationSuggestion(row: unknown) {
    if (!row || typeof row !== "object" || Array.isArray(row)) return null;
    const source = row as Record<string, unknown>;
    const address =
      source.address && typeof source.address === "object" && !Array.isArray(source.address)
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
      typeof source.display_name === "string" ? source.display_name.split(",")[0] : "",
    );
    if (!mainText) return null;
    const city = first(address.city, address.town, address.village, address.county);
    const state = first(address.state);
    const country = first(address.country);
    const secondaryText = [city !== mainText ? city : "", state, country].filter(Boolean).join(", ");
    return {
      placeId: String(source.place_id ?? source.osm_id ?? ""),
      mainText,
      secondaryText,
      latitude: Number(source.lat),
      longitude: Number(source.lon),
      displayName: String(source.display_name ?? [mainText, secondaryText].filter(Boolean).join(", ")),
      city: first(address.city, address.town, address.village, address.county, address.state),
      locality: first(address.neighbourhood, address.suburb, address.city_district, city),
      district: first(address.county),
      state,
      country,
      countryCode: first(address.country_code).toUpperCase(),
      postalCode: first(address.postcode),
    };
  }
}
