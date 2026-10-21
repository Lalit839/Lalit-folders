import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { existsSync, readdirSync } from "node:fs";
import { basename, extname, join } from "node:path";

const CONTENT_TYPES: Record<string, string> = {
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".gif": "image/gif",
  ".ico": "image/x-icon",
  ".json": "application/json",
};

const ALLOWED_EXTENSIONS = new Set(Object.keys(CONTENT_TYPES));

const SAFE_NAME = /^[A-Za-z0-9._-]+$/;

export const MEDIA_CATEGORIES = [
  "icons",
  "amenities",
  "venues",
  "banners",
] as const;
export type MediaCategory = (typeof MEDIA_CATEGORIES)[number];

export interface MediaFile {
  path: string;
  contentType: string;
}

export interface MediaManifest {
  baseUrl: string | null;
  icons: Record<string, string>;
  amenities: Record<string, string>;
  banners: { name: string; url: string }[];
  generatedAt: string;
}

@Injectable()
export class MediaService {
  private readonly root: string;

  constructor(private readonly config: ConfigService) {
    this.root = join(process.cwd(), "media");
  }

  /** Public URL for a media path relative to a media category, e.g. publicUrl('icons/football.svg'). */
  publicUrl(relative: string): string {
    const base = this.config.get<string>("MEDIA_BASE_URL");
    const clean = relative.replace(/^\/+/, "");
    return base
      ? `${base.replace(/\/+$/, "")}/${clean}`
      : `/api/v1/media/${clean}`;
  }

  /** Public URL for a sport/category icon derived from its sportCode, e.g. 'football' -> /api/v1/media/icons/football.png. */
  activityIconUrl(sportCode: string | null | undefined): string | null {
    const key = this.slugify(sportCode);
    if (!key) return null;
    for (const ext of [".png", ".webp", ".jpg", ".svg"]) {
      const relative = `icons/${key}${ext}`;
      if (existsSync(join(this.root, relative)))
        return this.publicUrl(relative);
    }
    return this.publicUrl(`icons/${key}.svg`);
  }

  /** Public URL for an amenity icon derived from its display name, e.g. 'Floodlights' -> /api/v1/media/amenities/floodlights.svg. */
  amenityIconUrl(name: string | null | undefined): string | null {
    const key = this.slugify(name);
    return key ? this.publicUrl(`amenities/${key}.svg`) : null;
  }

  private slugify(value: string | null | undefined): string {
    if (!value) return "";
    return value
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
  }

  getFile(
    category: "icons" | "amenities" | "banners",
    filename: string,
  ): MediaFile {
    const name = this.validateFile(filename);
    return this.resolve(category, name);
  }

  getVenueFile(venueSlug: string, filename: string): MediaFile {
    const venue = this.sanitizeName(venueSlug, "venue");
    const file = this.validateFile(filename);
    return this.resolve(join("venues", venue), file);
  }

  getManifest(): MediaManifest {
    const mapFromFolder = (
      category: "icons" | "amenities",
    ): Record<string, string> => {
      const result: Record<string, string> = {};
      for (const name of this.listFiles(category)) {
        result[basename(name, extname(name))] = this.publicUrl(
          `${category}/${name}`,
        );
      }
      return result;
    };
    const banners = this.listFiles("banners").map((name) => ({
      name: basename(name, extname(name)),
      url: this.publicUrl(`banners/${name}`),
    }));
    return {
      baseUrl: this.config.get<string>("MEDIA_BASE_URL") ?? null,
      icons: mapFromFolder("icons"),
      amenities: mapFromFolder("amenities"),
      banners,
      generatedAt: new Date().toISOString(),
    };
  }

  private listFiles(category: "icons" | "amenities" | "banners"): string[] {
    const dir = join(this.root, category);
    try {
      return readdirSync(dir)
        .filter(
          (name) =>
            !name.startsWith(".") &&
            ALLOWED_EXTENSIONS.has(extname(name).toLowerCase()),
        )
        .sort();
    } catch {
      return [];
    }
  }

  private validateFile(filename: string): string {
    const name = basename(filename);
    if (
      name !== filename ||
      !name ||
      name.startsWith(".") ||
      !SAFE_NAME.test(name)
    ) {
      throw new BadRequestException("Invalid file name");
    }
    const ext = extname(name).toLowerCase();
    if (!ALLOWED_EXTENSIONS.has(ext))
      throw new BadRequestException("Unsupported media type");
    return name;
  }

  private sanitizeName(value: string, what: string): string {
    if (
      !SAFE_NAME.test(value) ||
      value.startsWith(".") ||
      value.includes("..")
    ) {
      throw new BadRequestException(`Invalid ${what} name`);
    }
    return value;
  }

  private resolve(category: string, filename: string): MediaFile {
    const name = this.validateFile(filename);
    const filePath = join(this.root, category, name);
    if (
      !filePath.startsWith(this.root + "\\") &&
      !filePath.startsWith(this.root + "/")
    ) {
      throw new BadRequestException("Invalid media path");
    }
    if (!existsSync(filePath)) throw new NotFoundException("Media not found");
    const contentType =
      CONTENT_TYPES[extname(name).toLowerCase()] ?? "application/octet-stream";
    return { path: filePath, contentType };
  }
}
