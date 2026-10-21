import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createHash } from "crypto";

const ALLOWED_VENUE_IMAGE_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/avif",
]);

const MAX_VENUE_IMAGE_BYTES = 8 * 1024 * 1024;

export type CloudinaryVenueImage = {
  url: string;
  secureUrl: string;
  publicId: string;
  resourceType: string;
  format?: string;
  width?: number;
  height?: number;
  bytes?: number;
  optimizedUrl: string;
};

export type VenueUploadFile = {
  originalname?: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
};

@Injectable()
export class CloudinaryService {
  private readonly cloudName?: string;
  private readonly apiKey?: string;
  private readonly apiSecret?: string;
  private readonly folder: string;

  constructor(private readonly config: ConfigService) {
    this.cloudName = this.config.get<string>("CLOUDINARY_CLOUD_NAME");
    this.apiKey = this.config.get<string>("CLOUDINARY_API_KEY");
    this.apiSecret = this.config.get<string>("CLOUDINARY_API_SECRET");
    this.folder =
      this.config.get<string>("CLOUDINARY_FOLDER") || "activ/venues";
  }

  async uploadVenueImage(
    file: VenueUploadFile,
    venueId: string,
  ): Promise<CloudinaryVenueImage> {
    this.ensureConfigured();
    this.validateVenueImage(file);

    const timestamp = Math.floor(Date.now() / 1000);
    const folder = `${this.folder}/${venueId}`;
    const params = {
      folder,
      timestamp: String(timestamp),
    };
    const signature = this.sign(params);
    const form = new FormData();
    form.set("api_key", this.apiKey!);
    form.set("timestamp", params.timestamp);
    form.set("folder", folder);
    form.set("signature", signature);
    form.set(
      "file",
      new Blob([new Uint8Array(file.buffer)], { type: file.mimetype }),
      this.safeFilename(file.originalname),
    );

    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${this.cloudName}/image/upload`,
      { method: "POST", body: form },
    );
    const data = (await response.json().catch(() => ({}))) as Record<
      string,
      unknown
    >;
    if (!response.ok) {
      throw new ServiceUnavailableException(
        "Cloudinary venue image upload failed",
      );
    }

    const secureUrl = String(data.secure_url || data.url || "");
    const publicId = String(data.public_id || "");
    if (!secureUrl || !publicId) {
      throw new ServiceUnavailableException(
        "Cloudinary upload response was invalid",
      );
    }

    return {
      url: secureUrl,
      secureUrl,
      publicId,
      resourceType: String(data.resource_type || "image"),
      format: data.format ? String(data.format) : undefined,
      width: this.optionalNumber(data.width),
      height: this.optionalNumber(data.height),
      bytes: this.optionalNumber(data.bytes),
      optimizedUrl: this.optimizedVenueUrl(publicId),
    };
  }

  async deleteVenueImage(publicId?: string | null) {
    if (!publicId) return;
    this.ensureConfigured();

    const timestamp = Math.floor(Date.now() / 1000);
    const params = {
      public_id: publicId,
      timestamp: String(timestamp),
    };
    const form = new FormData();
    form.set("api_key", this.apiKey!);
    form.set("timestamp", params.timestamp);
    form.set("public_id", publicId);
    form.set("signature", this.sign(params));

    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${this.cloudName}/image/destroy`,
      { method: "POST", body: form },
    );
    if (!response.ok) {
      throw new ServiceUnavailableException(
        "Cloudinary venue image delete failed",
      );
    }
  }

  optimizedVenueUrl(publicId: string, width = 1200) {
    this.ensureConfigured();
    return `https://res.cloudinary.com/${this.cloudName}/image/upload/f_auto,q_auto,w_${width}/${publicId}`;
  }

  private validateVenueImage(file: VenueUploadFile) {
    if (!file) throw new BadRequestException("Venue image file is required");
    if (!ALLOWED_VENUE_IMAGE_MIME_TYPES.has(file.mimetype)) {
      throw new BadRequestException("Unsupported venue image type");
    }
    if (!file.buffer?.length)
      throw new BadRequestException("Venue image file is empty");
    if (file.size > MAX_VENUE_IMAGE_BYTES) {
      throw new BadRequestException("Venue image must be 8MB or smaller");
    }
  }

  private ensureConfigured() {
    if (!this.cloudName || !this.apiKey || !this.apiSecret) {
      throw new ServiceUnavailableException(
        "Cloudinary venue image configuration is missing",
      );
    }
  }

  private sign(params: Record<string, string>) {
    const base = Object.keys(params)
      .sort()
      .map((key) => `${key}=${params[key]}`)
      .join("&");
    return createHash("sha1").update(`${base}${this.apiSecret}`).digest("hex");
  }

  private optionalNumber(value: unknown) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }

  private safeFilename(filename?: string) {
    const name = filename
      ?.split(/[\\/]/)
      .pop()
      ?.replace(/[^a-zA-Z0-9._-]/g, "_");
    return name || "venue-image";
  }
}
