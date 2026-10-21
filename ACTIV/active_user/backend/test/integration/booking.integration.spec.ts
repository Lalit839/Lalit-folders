import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { BookingService } from '../../src/booking/booking.service';

const enabled = process.env.RUN_INTEGRATION_TESTS === '1';

(enabled ? describe : describe.skip)('booking concurrency (PostgreSQL)', () => {
  const prisma = new PrismaClient();
  let service: BookingService;
  const suffix = randomUUID();
  let userA: string;
  let userB: string;
  let slotId: string;
  let facilityId: string;
  let venueId: string;
  let partnerId: string;
  let activityId: string;

  beforeAll(async () => {
    service = new BookingService(prisma as never);
    const user = await prisma.user.create({ data: { phoneE164: `+919${suffix.replace(/-/g, '').slice(0, 9)}` } });
    const secondUser = await prisma.user.create({ data: { phoneE164: `+918${suffix.replace(/-/g, '').slice(0, 9)}` } });
    userA = user.id;
    userB = secondUser.id;
    const partner = await prisma.partner.create({ data: { legalName: `Integration ${suffix}`, status: 'ACTIVE' } });
    partnerId = partner.id;
    const activity = await prisma.activity.create({ data: { sportCode: `test-${suffix.slice(0, 8)}`, name: 'Integration Activity', status: 'PUBLISHED' } });
    activityId = activity.id;
    const venue = await prisma.venue.create({ data: { partnerId, name: `Integration Venue ${suffix}`, cityCode: 'TST', latitude: 28.6139, longitude: 77.2090, status: 'PUBLISHED', policyVersion: 'v1', activities: { create: { activityId, status: 'APPROVED' } } } });
    venueId = venue.id;
    const facility = await prisma.facility.create({ data: { venueId, activityId, name: 'Court 1', capacity: 1 } });
    facilityId = facility.id;
    const slot = await prisma.slot.create({ data: { facilityId, startsAt: new Date(Date.now() + 3_600_000), endsAt: new Date(Date.now() + 7_200_000), capacity: 1, pricePaise: 10000 } });
    slotId = slot.id;
  });

  afterAll(async () => {
    await prisma.bookingAttempt.deleteMany({ where: { slotId } });
    await prisma.slot.deleteMany({ where: { id: slotId } });
    await prisma.facility.deleteMany({ where: { id: facilityId } });
    await prisma.venue.deleteMany({ where: { id: venueId } });
    await prisma.partner.deleteMany({ where: { id: partnerId } });
    await prisma.activity.deleteMany({ where: { id: activityId } });
    await prisma.user.deleteMany({ where: { id: { in: [userA, userB] } } });
    await prisma.$disconnect();
  });

  it('allows only one hold for a single-capacity slot', async () => {
    const results = await Promise.allSettled([
      service.createAttempt(userA, `a-${suffix}`, slotId, 1),
      service.createAttempt(userB, `b-${suffix}`, slotId, 1),
    ]);
    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter((result) => result.status === 'rejected')).toHaveLength(1);
  });
});
