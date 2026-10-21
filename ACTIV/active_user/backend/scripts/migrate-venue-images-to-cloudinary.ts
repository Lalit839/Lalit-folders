import { Prisma, PrismaClient } from '@prisma/client';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { basename } from 'node:path';

type CloudinaryUpload = {
  secure_url?: string;
  url?: string;
  public_id?: string;
  resource_type?: string;
  format?: string;
  width?: number;
  height?: number;
  bytes?: number;
};

type ExistingImage = {
  id: string;
  venueId: string;
  url: string;
  metadata: Prisma.JsonValue;
  isPrimary: boolean;
  sortOrder: number;
};

const prisma = new PrismaClient();
const dryRun = process.argv.includes('--dry-run');
const limitArg = process.argv.find((arg) => arg.startsWith('--limit='));
const limit = limitArg ? Number(limitArg.replace('--limit=', '')) : undefined;

loadEnv();

const cloudName = env('CLOUDINARY_CLOUD_NAME');
const apiKey = env('CLOUDINARY_API_KEY');
const apiSecret = env('CLOUDINARY_API_SECRET');
const rootFolder = env('CLOUDINARY_FOLDER') || 'activ/venues';

function loadEnv() {
  try {
    const file = readFileSync('.env', 'utf8');
    for (const line of file.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const index = trimmed.indexOf('=');
      if (index === -1) continue;
      const key = trimmed.slice(0, index).trim();
      const value = trimmed.slice(index + 1).trim().replace(/^['"]|['"]$/g, '');
      if (!process.env[key]) process.env[key] = value;
    }
  } catch {
    // Environment may already be provided by the host.
  }
}

function env(key: string) {
  return (process.env[key] || '').trim();
}

function requireCloudinaryConfig() {
  const missing = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET']
    .filter((key) => !env(key));
  if (missing.length) throw new Error(`Missing Cloudinary env vars: ${missing.join(', ')}`);
}

function metadataObject(value: Prisma.JsonValue | null | undefined): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? { ...(value as Record<string, unknown>) }
    : {};
}

function imageUrlsFromMetadata(value: Prisma.JsonValue | null | undefined): string[] {
  const metadata = metadataObject(value);
  const urls = metadata.imageUrls;
  return Array.isArray(urls) ? urls.filter((url): url is string => typeof url === 'string' && url.trim().length > 0) : [];
}

function cloudinaryPublicId(value: Prisma.JsonValue | null | undefined) {
  const metadata = metadataObject(value);
  const id = metadata.cloudinaryPublicId;
  return typeof id === 'string' && id.trim() ? id.trim() : null;
}

function isCloudinaryUrl(url: string) {
  return /\/\/res\.cloudinary\.com\//i.test(url);
}

function sign(params: Record<string, string>) {
  const base = Object.keys(params)
    .sort()
    .map((key) => `${key}=${params[key]}`)
    .join('&');
  return createHash('sha1').update(`${base}${apiSecret}`).digest('hex');
}

function optimizedUrl(publicId: string, width = 1200) {
  return `https://res.cloudinary.com/${cloudName}/image/upload/f_auto,q_auto,w_${width}/${publicId}`;
}

async function uploadRemoteVenueImage(venueId: string, sourceUrl: string): Promise<Required<Pick<CloudinaryUpload, 'secure_url' | 'public_id'>> & CloudinaryUpload> {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const folder = `${rootFolder}/${venueId}`;
  const params = { folder, timestamp };
  const form = new FormData();
  form.set('api_key', apiKey);
  form.set('timestamp', timestamp);
  form.set('folder', folder);
  form.set('file', sourceUrl);
  form.set('signature', sign(params));

  const response = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/image/upload`, {
    method: 'POST',
    body: form,
  });
  const data = (await response.json().catch(() => ({}))) as CloudinaryUpload & { error?: { message?: string } };
  if (!response.ok || !data.public_id || !(data.secure_url || data.url)) {
    const message = data.error?.message || `Cloudinary upload failed for ${sourceUrl}`;
    if (/invalid signature|api key|api secret|unauthorized/i.test(message)) {
      throw new Error(`CLOUDINARY_AUTH_FAILED: ${message}`);
    }
    throw new Error(message);
  }
  return { ...data, public_id: data.public_id, secure_url: data.secure_url || data.url! };
}

function cloudinaryMetadata(upload: CloudinaryUpload, sourceUrl: string, existing?: Prisma.JsonValue): Prisma.InputJsonObject {
  return {
    ...metadataObject(existing),
    provider: 'cloudinary',
    sourceUrl,
    secureUrl: upload.secure_url,
    optimizedUrl: optimizedUrl(upload.public_id!),
    cloudinaryPublicId: upload.public_id,
    resourceType: upload.resource_type || 'image',
    format: upload.format,
    width: upload.width,
    height: upload.height,
    bytes: upload.bytes,
  } as Prisma.InputJsonObject;
}

async function migrateExistingImage(image: ExistingImage) {
  if (cloudinaryPublicId(image.metadata) || isCloudinaryUrl(image.url)) {
    return { skipped: true, url: image.url };
  }
  if (!/^https?:\/\//i.test(image.url)) {
    return { skipped: true, url: image.url, reason: 'not a remote URL' };
  }
  if (dryRun) return { uploaded: true, url: image.url };
  const upload = await uploadRemoteVenueImage(image.venueId, image.url);
  await prisma.partnerVenueImage.update({
    where: { id: image.id },
    data: {
      url: upload.secure_url,
      metadata: cloudinaryMetadata(upload, image.url, image.metadata),
    },
  });
  return { uploaded: true, url: upload.secure_url };
}

async function main() {
  requireCloudinaryConfig();
  const venues = await prisma.venue.findMany({
    orderBy: { name: 'asc' },
    take: limit && Number.isFinite(limit) && limit > 0 ? limit : undefined,
    select: {
      id: true,
      name: true,
      metadata: true,
      partnerImages: {
        orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
        select: { id: true, venueId: true, url: true, metadata: true, isPrimary: true, sortOrder: true },
      },
    },
  });

  let uploaded = 0;
  let skipped = 0;
  let failed = 0;

  for (const venue of venues) {
    const metadataUrls = imageUrlsFromMetadata(venue.metadata);
    const existingBySource = new Map<string, ExistingImage>();
    const existingByUrl = new Map<string, ExistingImage>();
    for (const image of venue.partnerImages) {
      existingByUrl.set(image.url, image);
      const sourceUrl = metadataObject(image.metadata).sourceUrl;
      if (typeof sourceUrl === 'string') existingBySource.set(sourceUrl, image);
    }

    const cloudinaryUrls: string[] = [];
    const inputUrls = metadataUrls.length ? metadataUrls : venue.partnerImages.map((image) => image.url);
    for (const [index, sourceUrl] of inputUrls.entries()) {
      try {
        const existing = existingBySource.get(sourceUrl) || existingByUrl.get(sourceUrl);
        if (existing) {
          const result = await migrateExistingImage(existing);
          if (result.uploaded) uploaded += 1;
          else skipped += 1;
          cloudinaryUrls.push(result.url);
          continue;
        }

        if (isCloudinaryUrl(sourceUrl)) {
          skipped += 1;
          cloudinaryUrls.push(sourceUrl);
          continue;
        }

        if (dryRun) {
          uploaded += 1;
          cloudinaryUrls.push(sourceUrl);
          continue;
        }

        const upload = await uploadRemoteVenueImage(venue.id, sourceUrl);
        const sortOrder = venue.partnerImages.length + index + 1;
        await prisma.partnerVenueImage.create({
          data: {
            venueId: venue.id,
            url: upload.secure_url,
            caption: `${venue.name} ${index + 1}`,
            sortOrder,
            isPrimary: index === 0 && !venue.partnerImages.some((image) => image.isPrimary),
            metadata: cloudinaryMetadata(upload, sourceUrl),
          },
        });
        uploaded += 1;
        cloudinaryUrls.push(upload.secure_url);
      } catch (error) {
        if (error instanceof Error && error.message.startsWith('CLOUDINARY_AUTH_FAILED:')) throw error;
        failed += 1;
        console.error(`Failed ${venue.name} ${basename(sourceUrl)}: ${error instanceof Error ? error.message : String(error)}`);
      }
    }

    if (!dryRun && cloudinaryUrls.length) {
      const metadata = metadataObject(venue.metadata);
      await prisma.venue.update({
        where: { id: venue.id },
        data: {
          metadata: {
            ...metadata,
            image: cloudinaryUrls[0],
            imagePath: cloudinaryUrls[0],
            imageUrls: cloudinaryUrls,
          } as Prisma.InputJsonObject,
        },
      });
    }
    console.log(`${dryRun ? '[dry-run] ' : ''}${venue.name}: ${cloudinaryUrls.length} image URL(s) ready`);
  }

  console.log(`Done. Uploaded: ${uploaded}, skipped: ${skipped}, failed: ${failed}`);
  if (dryRun) console.log('Dry run only. Re-run without --dry-run to update Cloudinary and PostgreSQL.');
}

main()
  .catch((error) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
