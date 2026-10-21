import { PrismaClient, SlotStatus } from '@prisma/client';

const prisma = new PrismaClient();
const daysArg = process.argv.find((arg) => arg.startsWith('--days='));
const days = Math.max(1, Math.min(90, Number(daysArg?.replace('--days=', '') || 30)));
const dryRun = process.argv.includes('--dry-run');

function istSlotStart(dayOffset: number, hour: number) {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + dayOffset, hour - 6, 30));
}

function dateKey(value: Date) {
  return value.toISOString();
}

async function main() {
  const facilities = await prisma.facility.findMany({
    where: { venue: { status: 'PUBLISHED' } },
    orderBy: [{ venue: { name: 'asc' } }, { name: 'asc' }],
    select: {
      id: true,
      name: true,
      capacity: true,
      venue: { select: { name: true } },
      slots: {
        orderBy: { startsAt: 'desc' },
        take: 120,
        select: { startsAt: true, endsAt: true, pricePaise: true, capacity: true },
      },
    },
  });

  let created = 0;
  let skipped = 0;

  for (const facility of facilities) {
    if (!facility.slots.length) {
      console.log(`Skipped ${facility.venue.name} / ${facility.name}: no historical slot template`);
      skipped += 1;
      continue;
    }

    const hours = [...new Set(
      facility.slots
        .map((slot) => slot.startsAt.getUTCHours() + 6 + (slot.startsAt.getUTCMinutes() >= 30 ? 1 : 0))
        .map((hour) => ((hour - 1) % 24) + 1),
    )].sort((a, b) => a - b);
    const template = facility.slots[0];
    const durationMs = Math.max(30 * 60 * 1000, template.endsAt.getTime() - template.startsAt.getTime());
    const starts = Array.from({ length: days + 1 }, (_, dayOffset) =>
      hours.map((hour) => istSlotStart(dayOffset, hour)),
    ).flat();
    const existing = await prisma.slot.findMany({
      where: { facilityId: facility.id, startsAt: { in: starts } },
      select: { startsAt: true },
    });
    const existingStarts = new Set(existing.map((slot) => dateKey(slot.startsAt)));
    const rows = starts
      .filter((startsAt) => !existingStarts.has(dateKey(startsAt)))
      .map((startsAt) => ({
        facilityId: facility.id,
        startsAt,
        endsAt: new Date(startsAt.getTime() + durationMs),
        capacity: template.capacity || facility.capacity,
        bookedQuantity: 0,
        status: SlotStatus.AVAILABLE,
        pricePaise: template.pricePaise,
      }));

    if (rows.length && !dryRun) {
      await prisma.slot.createMany({ data: rows });
    }
    created += rows.length;
    console.log(`${dryRun ? '[dry-run] ' : ''}${facility.venue.name} / ${facility.name}: ${rows.length} future slot(s)`);
  }

  console.log(`Done. ${dryRun ? 'Would create' : 'Created'} ${created} slot(s). Skipped facilities: ${skipped}.`);
}

main()
  .catch((error) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
