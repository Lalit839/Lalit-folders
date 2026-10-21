import { PrismaClient, ApprovalStatus, CatalogueStatus, PartnerStatus, SlotStatus, ActivityType, BookingStatus, AttemptStatus, PaymentStatus, RefundStatus, ReviewStatus, ContentStatus, CouponStatus, NotificationStatus, TicketStatus } from '@prisma/client';

const prisma = new PrismaClient();

interface ActivitySeed {
  sportCode: string;
  name: string;
  type: ActivityType;
}

const activities: ActivitySeed[] = [
  { sportCode: 'gym', name: 'Gym', type: ActivityType.SINGLE },
  { sportCode: 'yoga', name: 'Yoga Studio', type: ActivityType.SINGLE },
  { sportCode: 'pilates', name: 'Pilates', type: ActivityType.SINGLE },
  { sportCode: 'zumba', name: 'Zumba', type: ActivityType.SINGLE },
  { sportCode: 'dance', name: 'Dance Studio', type: ActivityType.SINGLE },
  { sportCode: 'crossfit', name: 'CrossFit', type: ActivityType.SINGLE },
  { sportCode: 'hiit', name: 'HIIT Studio', type: ActivityType.SINGLE },
  { sportCode: 'bowling', name: 'Bowling', type: ActivityType.SINGLE },
  { sportCode: 'trampoline', name: 'Trampoline', type: ActivityType.SINGLE },
  { sportCode: 'adventure', name: 'Adventure Sports', type: ActivityType.SINGLE },
  { sportCode: 'rock_climbing', name: 'Rock Climbing', type: ActivityType.SINGLE },
  { sportCode: 'bouldering', name: 'Bouldering', type: ActivityType.SINGLE },
  { sportCode: 'boxing', name: 'Boxing', type: ActivityType.SINGLE },
  { sportCode: 'mma', name: 'MMA', type: ActivityType.SINGLE },
  { sportCode: 'martial_arts', name: 'Martial Arts', type: ActivityType.SINGLE },
  { sportCode: 'archery', name: 'Archery', type: ActivityType.SINGLE },
  { sportCode: 'shooting', name: 'Shooting', type: ActivityType.SINGLE },
  { sportCode: 'swimming', name: 'Swimming', type: ActivityType.SINGLE },
  { sportCode: 'skating', name: 'Skating', type: ActivityType.SINGLE },
  { sportCode: 'equestrian', name: 'Equestrian', type: ActivityType.SINGLE },
  { sportCode: 'badminton', name: 'Badminton', type: ActivityType.COURT },
  { sportCode: 'tennis', name: 'Tennis', type: ActivityType.COURT },
  { sportCode: 'pickleball', name: 'Pickleball', type: ActivityType.COURT },
  { sportCode: 'padel', name: 'Padel', type: ActivityType.COURT },
  { sportCode: 'squash', name: 'Squash', type: ActivityType.COURT },
  { sportCode: 'basketball', name: 'Basketball', type: ActivityType.COURT },
  { sportCode: 'volleyball', name: 'Volleyball', type: ActivityType.COURT },
  { sportCode: 'padbol', name: 'Padbol', type: ActivityType.COURT },
  { sportCode: 'table_tennis', name: 'Table Tennis', type: ActivityType.TABLE },
  { sportCode: 'pool', name: 'Pool Table', type: ActivityType.TABLE },
  { sportCode: 'snooker', name: 'Snooker', type: ActivityType.TABLE },
  { sportCode: 'teqball', name: 'Teqball', type: ActivityType.TABLE },
  { sportCode: 'cricket_turf', name: 'Cricket Turf', type: ActivityType.TURF },
  { sportCode: 'football_turf', name: 'Football Turf', type: ActivityType.TURF },
  { sportCode: 'hockey', name: 'Hockey', type: ActivityType.TURF },
  { sportCode: 'paintball', name: 'Paintball', type: ActivityType.TURF },
  { sportCode: 'frisbee', name: 'Frisbee', type: ActivityType.TURF },
  { sportCode: 'cricket_nets', name: 'Cricket Nets', type: ActivityType.CRICKET_NETS },
];

const PRICES: Record<string, number> = {
  football_turf: 2000, // paise 200000
  cricket_turf: 2500,
  hockey: 1500,
  badminton: 600,
  pickleball: 500,
  tennis: 900,
  squash: 700,
  padel: 900,
  basketball: 500,
  volleyball: 400,
  table_tennis: 300,
  snooker: 350,
  pool: 300,
  gym: 500,
  yoga: 300,
  pilates: 350,
  crossfit: 450,
  zumba: 300,
  dance: 400,
  swimming: 450,
  cricket_nets: 1000,
  boxing: 400,
  mma: 450,
  archery: 400,
  shooting: 500,
};

const FACILITY_PREFIX: Record<string, string> = {
  football_turf: 'Turf',
  cricket_turf: 'Turf',
  hockey: 'Turf',
  badminton: 'Court',
  pickleball: 'Court',
  tennis: 'Court',
  squash: 'Court',
  padel: 'Court',
  basketball: 'Court',
  volleyball: 'Court',
  table_tennis: 'Table',
  snooker: 'Table',
  pool: 'Table',
  gym: 'Studio',
  yoga: 'Studio',
  pilates: 'Studio',
  crossfit: 'Studio',
  zumba: 'Studio',
  dance: 'Studio',
  swimming: 'Pool',
  cricket_nets: 'Net',
  boxing: 'Ring',
  mma: 'Ring',
  archery: 'Lane',
  shooting: 'Lane',
};

interface VenueSeed {
  key: string;
  name: string;
  cityCode: string;
  latitude: number;
  longitude: number;
  sportCodes: string[];
  imageSeed: string;
  imageCount: number;
  rating: number;
  reviewCount: number;
}

const venueSeeds: VenueSeed[] = [
  {
    key: 'arena',
    name: 'ACTIV Demo Arena',
    cityCode: 'IND',
    latitude: 22.7196,
    longitude: 75.8577,
    sportCodes: ['football_turf', 'cricket_turf', 'badminton', 'swimming'],
    imageSeed: 'activ-arena',
    imageCount: 6,
    rating: 4.5,
    reviewCount: 128,
  },
  {
    key: 'smash',
    name: 'Smash Court Arena',
    cityCode: 'IND',
    latitude: 22.7293,
    longitude: 75.8656,
    sportCodes: ['badminton', 'pickleball', 'table_tennis'],
    imageSeed: 'activ-smash',
    imageCount: 5,
    rating: 4.4,
    reviewCount: 96,
  },
  {
    key: 'spark',
    name: 'Spark Sports Hub',
    cityCode: 'BOM',
    latitude: 19.076,
    longitude: 72.8777,
    sportCodes: ['tennis', 'football_turf'],
    imageSeed: 'activ-spark',
    imageCount: 5,
    rating: 4.2,
    reviewCount: 71,
  },
  {
    key: 'greenlawn',
    name: 'Green Lawn Club',
    cityCode: 'BOM',
    latitude: 19.0596,
    longitude: 72.8295,
    sportCodes: ['cricket_turf', 'football_turf', 'hockey'],
    imageSeed: 'activ-greenlawn',
    imageCount: 5,
    rating: 4.6,
    reviewCount: 154,
  },
  {
    key: 'pulse',
    name: 'Pulse Fitness & Yoga',
    cityCode: 'DEL',
    latitude: 28.6139,
    longitude: 77.209,
    sportCodes: ['gym', 'yoga', 'pilates', 'crossfit', 'zumba'],
    imageSeed: 'activ-pulse',
    imageCount: 5,
    rating: 4.3,
    reviewCount: 88,
  },
  {
    key: 'metro',
    name: 'Metro Table & Pool Club',
    cityCode: 'DEL',
    latitude: 28.7041,
    longitude: 77.1025,
    sportCodes: ['table_tennis', 'snooker', 'pool'],
    imageSeed: 'activ-metro',
    imageCount: 5,
    rating: 4.1,
    reviewCount: 64,
  },
  {
    key: 'gladiator',
    name: 'Gladiator Sports Arena',
    cityCode: 'BLR',
    latitude: 12.9716,
    longitude: 77.5946,
    sportCodes: ['badminton', 'squash', 'padel'],
    imageSeed: 'activ-gladiator',
    imageCount: 5,
    rating: 4.4,
    reviewCount: 53,
  },
  {
    key: 'delta',
    name: 'Delta Combat Club',
    cityCode: 'BLR',
    latitude: 12.9352,
    longitude: 77.6245,
    sportCodes: ['boxing', 'mma'],
    imageSeed: 'activ-delta',
    imageCount: 5,
    rating: 4.7,
    reviewCount: 42,
  },
  {
    key: 'ocean',
    name: 'Ocean Swim & Fitness',
    cityCode: 'HYD',
    latitude: 17.385,
    longitude: 78.4867,
    sportCodes: ['swimming', 'gym', 'crossfit'],
    imageSeed: 'activ-ocean',
    imageCount: 5,
    rating: 4.5,
    reviewCount: 61,
  },
  {
    key: 'zen',
    name: 'Zen Yoga & Pilates',
    cityCode: 'DEL',
    latitude: 28.5355,
    longitude: 77.391,
    sportCodes: ['yoga', 'pilates', 'dance'],
    imageSeed: 'activ-zen',
    imageCount: 5,
    rating: 4.8,
    reviewCount: 47,
  },
  {
    key: 'bullz',
    name: 'Bullz Cricket Nets',
    cityCode: 'BOM',
    latitude: 19.1136,
    longitude: 72.8697,
    sportCodes: ['cricket_nets', 'cricket_turf'],
    imageSeed: 'activ-bullz',
    imageCount: 5,
    rating: 4.2,
    reviewCount: 38,
  },
  {
    key: 'neo',
    name: 'Neo Indoor Basketball',
    cityCode: 'PUN',
    latitude: 18.5204,
    longitude: 73.8567,
    sportCodes: ['basketball', 'volleyball'],
    imageSeed: 'activ-neo',
    imageCount: 5,
    rating: 4.3,
    reviewCount: 33,
  },
  {
    key: 'archer',
    name: 'Archer Indoor Range',
    cityCode: 'IND',
    latitude: 22.7238,
    longitude: 75.8575,
    sportCodes: ['archery', 'shooting'],
    imageSeed: 'activ-archer',
    imageCount: 5,
    rating: 4.6,
    reviewCount: 29,
  },
  {
    key: 'summit',
    name: 'Summit TT & Sports',
    cityCode: 'BLR',
    latitude: 12.9784,
    longitude: 77.6408,
    sportCodes: ['table_tennis', 'football_turf'],
    imageSeed: 'activ-summit',
    imageCount: 5,
    rating: 4.1,
    reviewCount: 51,
  },
];

interface DemoUserSeed {
  phoneE164: string;
  name: string;
}

const DEMO_USERS: DemoUserSeed[] = [
  { phoneE164: '+919999999999', name: 'Demo User' },
  { phoneE164: '+919876543210', name: 'Priya Sharma' },
  { phoneE164: '+919012345678', name: 'Rahul Verma' },
  { phoneE164: '+919888777666', name: 'Sneha Patel' },
];

const DEMO_PHONES = DEMO_USERS.map((user) => user.phoneE164);

const COUPON_CODES = ['ACTIV20', 'FLAT100', 'OFFPEAK15', 'WELCOME100'];
const FAQ_QUESTIONS = [
  'How do I book a sports venue?',
  'How do I book a court?',
  'Can I cancel my booking?',
  'Can I reschedule my booking?',
  'When will I receive my booking confirmation?',
  'What payment methods are accepted?',
  'What happens if I arrive late?',
  'Do venues provide equipment?',
  'How do refunds work?',
  'Can I book for a large group?',
  'What is the reschedule policy?',
  'How do I use a coupon?',
];

function imageUrls(seed: string, count: number): string[] {
  return Array.from({ length: count }, (_, i) => `https://picsum.photos/seed/${seed}-${i + 1}/900/600`);
}

function buildMetadata(name: string, imageSeed: string, imageCount: number, rating: number, reviewCount: number) {
  return {
    rating,
    reviewCount,
    amenities: [
      { name: 'Floodlights', iconAsset: '' },
      { name: 'Parking', iconAsset: '' },
      { name: 'Showers', iconAsset: '' },
      { name: 'Water Dispenser', iconAsset: '' },
      { name: 'Lockers', iconAsset: '' },
    ],
    rules: [
      'Please arrive 15 minutes before your scheduled slot.',
      'Proper sports footwear is mandatory.',
      'No food or beverages with stains allowed on the court.',
      'Children under 12 must be accompanied by an adult.',
      'Report any equipment damage to the front desk.',
    ],
    offers: [
      { id: `offer-${imageSeed}-1`, activityName: name, title: 'Opening Offer', description: 'Flat 20% off on your first booking with code ACTIV20.' },
      { id: `offer-${imageSeed}-2`, activityName: name, title: 'Off-Peak Saver', description: 'Book weekday morning slots and save 10% extra.' },
    ],
    imageUrls: imageUrls(imageSeed, imageCount),
    cancellationPolicy: 'Free cancellation up to 12 hours before start. 50% refund between 12h and 3h. No refund within 3 hours of slot start.',
    faqs: [
      { question: 'Do I need to carry my own equipment?', answer: 'Yes, equipment is available at the venue but you should carry your own footwear and gear.' },
      { question: 'Can I reschedule my booking?', answer: 'Yes, once per booking up to 12 hours before the start time, subject to availability.' },
      { question: 'What is the cancellation policy?', answer: 'Full refund 12+ hours before start; 50% refund 3–12 hours before; no refund within 3 hours.' },
    ],
  };
}

function cityLabel(cityCode: string) {
  const labels: Record<string, string> = {
    IND: 'Indore',
    BOM: 'Mumbai',
    DEL: 'Delhi',
    BLR: 'Bengaluru',
    HYD: 'Hyderabad',
    PUN: 'Pune',
  };
  return labels[cityCode] ?? cityCode;
}

function venueContactPhone(index: number) {
  return `+91900000${String(index + 1).padStart(4, '0')}`;
}

// Build a Date at a given local (IST) hour for an absolute calendar day (relative offset from server "now").
function slotStart(dayOffset: number, hour: number): Date {
  const now = new Date();
  const utc = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + dayOffset, hour - 6, 30));
  return utc;
}

async function cleanupDemoData(): Promise<void> {
  console.log('Cleaning existing demo data...');
  const venueIds = (await prisma.venue.findMany({ where: { name: { in: venueSeeds.map((v) => v.name) } }, select: { id: true } })).map((item) => item.id);

  const byUser = { user: { phoneE164: { in: DEMO_PHONES } } };
  const byVenue = venueIds.length ? { slot: { facility: { venueId: { in: venueIds } } } } : undefined;

  await prisma.refund.deleteMany({ where: { OR: [{ booking: byUser }, byVenue ? { booking: byVenue } : undefined].filter(Boolean) as any } });
  await prisma.payment.deleteMany({ where: { OR: [{ booking: byUser }, byVenue ? { booking: byVenue } : undefined].filter(Boolean) as any } });
  await prisma.review.deleteMany({ where: { OR: [{ booking: byUser }, byVenue ? { booking: byVenue } : undefined].filter(Boolean) as any } });
  await prisma.bookingEvent.deleteMany({ where: { OR: [{ booking: byUser }, byVenue ? { booking: byVenue } : undefined].filter(Boolean) as any } });
  await prisma.notification.deleteMany({ where: { OR: [{ user: byUser.user }, byVenue ? { booking: { slot: { facility: { venueId: { in: venueIds } } } } } : undefined].filter(Boolean) as any } });
  await prisma.supportTicket.deleteMany({ where: { user: { phoneE164: { in: DEMO_PHONES } } } });
  await prisma.booking.deleteMany({ where: { OR: [{ user: { phoneE164: { in: DEMO_PHONES } } }, byVenue ? { slot: { facility: { venueId: { in: venueIds } } } } : undefined].filter(Boolean) as any } });
  await prisma.bookingAttempt.deleteMany({ where: { OR: [{ user: { phoneE164: { in: DEMO_PHONES } } }, byVenue ? { slot: { facility: { venueId: { in: venueIds } } } } : undefined].filter(Boolean) as any } });
  await prisma.savedVenue.deleteMany({ where: { OR: [{ user: { phoneE164: { in: DEMO_PHONES } } }, venueIds.length ? { venueId: { in: venueIds } } : undefined].filter(Boolean) as any } });
  await prisma.user.deleteMany({ where: { phoneE164: { in: DEMO_PHONES } } });

  await prisma.couponRedemption.deleteMany({ where: { coupon: { code: { in: COUPON_CODES } } } });
  await prisma.coupon.deleteMany({ where: { code: { in: COUPON_CODES } } });

  if (venueIds.length) {
    await prisma.venueActivity.deleteMany({ where: { venueId: { in: venueIds } } });
    await prisma.facility.deleteMany({ where: { venueId: { in: venueIds } } });
    await prisma.venue.deleteMany({ where: { id: { in: venueIds } } });
  }

  await prisma.faq.deleteMany({ where: { question: { in: FAQ_QUESTIONS } } });
  console.log('Cleaned existing demo data.');
}

interface DemoSlot {
  id: string;
  facilityId: string;
  pricePaise: bigint;
  startsAt: Date;
  endsAt: Date;
}

async function seedCatalog(): Promise<Map<string, DemoSlot>> {
  console.log('Seeding activities, venues, facilities, and slots...');
  const partner = await prisma.partner.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: { status: PartnerStatus.ACTIVE },
    create: { id: '00000000-0000-0000-0000-000000000001', legalName: 'ACTIV Demo Partner', status: PartnerStatus.ACTIVE },
  });

  await prisma.partnerBusinessProfile.upsert({
    where: { partnerId: partner.id },
    update: {
      businessName: 'ACTIV Demo Partner',
      ownerName: 'Amit Sharma',
      phoneE164: '+919000000000',
      city: 'Indore',
      state: 'Madhya Pradesh',
      kycStatus: PartnerKycStatus.APPROVED,
    },
    create: {
      partner: { connect: { id: partner.id } },
      businessName: 'ACTIV Demo Partner',
      ownerName: 'Amit Sharma',
      phoneE164: '+919000000000',
      city: 'Indore',
      state: 'Madhya Pradesh',
      kycStatus: PartnerKycStatus.APPROVED,
    },
  });

  for (const seed of activities) {
    await prisma.activity.upsert({
      where: { sportCode_name: { sportCode: seed.sportCode, name: seed.name } },
      update: { type: seed.type, status: CatalogueStatus.PUBLISHED },
      create: { sportCode: seed.sportCode, name: seed.name, type: seed.type, status: CatalogueStatus.PUBLISHED },
    });
  }

  const slotCache = new Map<string, DemoSlot>();

  for (const [index, seed] of venueSeeds.entries()) {
    console.log(`Seeding venue: ${seed.name}`);
    const metadata = buildMetadata(seed.name, seed.imageSeed, seed.imageCount, seed.rating, seed.reviewCount);
    const venue = await prisma.venue.create({
      data: {
        partnerId: partner.id,
        name: seed.name,
        cityCode: seed.cityCode,
        latitude: seed.latitude,
        longitude: seed.longitude,
        status: 'PUBLISHED',
        policyVersion: 'v1',
        metadata,
      },
    });

    await prisma.partnerVenueProfile.create({
      data: {
        partnerId: partner.id,
        venueId: venue.id,
        displayName: `${seed.name} Front Desk`,
        contactPhoneE164: venueContactPhone(index),
        addressLine1: `${seed.name}, ${cityLabel(seed.cityCode)}`,
        city: cityLabel(seed.cityCode),
        state: 'India',
        onboardingStatus: PartnerKycStatus.APPROVED,
      },
    });

    for (const sportCode of seed.sportCodes) {
      const activity = await prisma.activity.findFirstOrThrow({
        where: { sportCode, status: CatalogueStatus.PUBLISHED },
        select: { id: true, type: true },
      });

      await prisma.venueActivity.create({
        data: {
          venueId: venue.id,
          activityId: activity.id,
          status: ApprovalStatus.APPROVED,
        },
      });

      const facility = await prisma.facility.create({
        data: {
          venueId: venue.id,
          activityId: activity.id,
          name: `${FACILITY_PREFIX[sportCode] ?? 'Area'} 1 - ${sportsName(sportCode)}`,
          capacity: activity.type === ActivityType.SINGLE ? 20 : 8,
        },
      });

      const pricePaise = BigInt((PRICES[sportCode] ?? 500) * 100);
      const slotRows: Array<{
        dayOffset: number;
        hour: number;
        startsAt: Date;
        endsAt: Date;
      }> = [];
      for (const dayOffset of [-3, -2, -1, 0, 1, 2, 3, 4]) {
        for (const hour of [7, 8, 9, 10, 13, 14, 16, 17, 18, 19, 20]) {
          const startsAt = slotStart(dayOffset, hour);
          const endsAt = new Date(startsAt.getTime() + 60 * 60 * 1000);
          slotRows.push({ dayOffset, hour, startsAt, endsAt });
        }
      }

      await prisma.slot.createMany({
        data: slotRows.map((slot) => ({
          facilityId: facility.id,
          startsAt: slot.startsAt,
          endsAt: slot.endsAt,
          capacity: activity.type === ActivityType.SINGLE ? 20 : 8,
          bookedQuantity: 0,
          status: SlotStatus.AVAILABLE,
          pricePaise,
        })),
      });

      const createdSlots = await prisma.slot.findMany({
        where: { facilityId: facility.id },
        select: { id: true, startsAt: true },
      });
      const slotsByStart = new Map(createdSlots.map((slot) => [slot.startsAt.toISOString(), slot.id]));

      for (const slotRow of slotRows) {
        const slotId = slotsByStart.get(slotRow.startsAt.toISOString());
        if (!slotId) throw new Error(`Missing seeded slot for ${seed.key}|${sportCode}|${slotRow.dayOffset}|${slotRow.hour}`);
        slotCache.set(`${seed.key}|${sportCode}|${slotRow.dayOffset}|${slotRow.hour}`, {
          id: slotId,
          facilityId: facility.id,
          pricePaise,
          startsAt: slotRow.startsAt,
          endsAt: slotRow.endsAt,
        });
      }
    }
  }

  console.log(`Seeded catalog with ${slotCache.size} slots available for demo bookings.`);
  return slotCache;
}

function sportsName(sportCode: string): string {
  const match = activities.find((item) => item.sportCode === sportCode);
  return match?.name ?? sportCode;
}

async function seedCoupons(): Promise<void> {
  console.log('Seeding coupons...');
  const now = new Date();
  await prisma.coupon.createMany({
    data: [
      {
        code: 'ACTIV20',
        status: CouponStatus.ACTIVE,
        percentOff: 20,
        startsAt: new Date(now.getTime() - 24 * 3600 * 1000),
        endsAt: new Date(now.getTime() + 30 * 24 * 3600 * 1000),
        perUserLimit: 1,
      },
      {
        code: 'FLAT100',
        status: CouponStatus.ACTIVE,
        amountOffPaise: BigInt(10000),
        startsAt: new Date(now.getTime() - 24 * 3600 * 1000),
        endsAt: new Date(now.getTime() + 30 * 24 * 3600 * 1000),
        perUserLimit: 3,
      },
      {
        code: 'OFFPEAK15',
        status: CouponStatus.ACTIVE,
        percentOff: 15,
        startsAt: new Date(now.getTime() - 24 * 3600 * 1000),
        endsAt: new Date(now.getTime() + 30 * 24 * 3600 * 1000),
        perUserLimit: 5,
      },
      {
        code: 'WELCOME100',
        status: CouponStatus.ACTIVE,
        amountOffPaise: BigInt(10000),
        startsAt: new Date(now.getTime() - 24 * 3600 * 1000),
        endsAt: new Date(now.getTime() + 30 * 24 * 3600 * 1000),
        perUserLimit: 1,
      },
    ],
    skipDuplicates: true,
  });
  console.log('Seeded coupons.');
}

interface BookingSeed {
  code: string;
  status: BookingStatus;
  slotKey: string;
  quantity: number;
  attemptStatus: AttemptStatus;
  attemptExpiry: 'past' | 'future';
  paymentStatus: PaymentStatus;
  refund?: { amountPaise: bigint; status: RefundStatus };
  review?: { rating: number; body: string; reviewStatus?: ReviewStatus };
  rescheduleCount?: number;
  createdAt: number;
  eventChain: Array<{ from: string; to: string }>;
}

async function createBooking(user: { id: string }, booking: BookingSeed, slotCache: Map<string, DemoSlot>): Promise<{ id: string; bookingId: string; venueName: string }> {
  const slot = slotCache.get(booking.slotKey);
  if (!slot) throw new Error(`Missing slot for key ${booking.slotKey}`);

  const reserveSlot =
    booking.status === BookingStatus.CONFIRMED || booking.status === BookingStatus.COMPLETED;
  if (reserveSlot) {
    await prisma.slot.update({
      where: { id: slot.id },
      data: { bookedQuantity: { increment: booking.quantity } },
    });
  }

  const createdAt = new Date(Date.now() - booking.createdAt * 24 * 3600 * 1000);
  const subtotal = slot.pricePaise * BigInt(booking.quantity);
  const attempt = await prisma.bookingAttempt.create({
    data: {
      userId: user.id,
      slotId: slot.id,
      quantity: booking.quantity,
      status: booking.attemptStatus,
      expiresAt:
        booking.attemptExpiry === 'future'
          ? new Date(Date.now() + 2 * 3600 * 1000)
          : new Date(createdAt.getTime() - 12 * 3600 * 1000),
      idempotencyKey: `seed-attempt-${booking.code}`,
      quoteSnapshot: { subtotal: Number(subtotal), discount: 0, fees: 0, tax: 0, total: Number(subtotal), currency: 'INR' },
    },
  });

  const row = await prisma.booking.create({
    data: {
      publicCode: booking.code,
      userId: user.id,
      slotId: slot.id,
      attemptId: attempt.id,
      status: booking.status,
      policyVersion: 'v1',
      subtotalPaise: subtotal,
      discountPaise: BigInt(0),
      totalPaise: subtotal,
      rescheduleCount: booking.rescheduleCount ?? 0,
      startsAt: slot.startsAt,
      createdAt,
    },
  });

  const payment = await prisma.payment.create({
    data: {
      bookingId: row.id,
      provider: 'razorpay',
      providerOrderId: `demo_order_${booking.code}`,
      providerPaymentId: `demo_pay_${booking.code}`,
      status: booking.paymentStatus,
      amountPaise: subtotal,
      createdAt,
    },
  });

  if (booking.refund) {
    await prisma.refund.create({
      data: {
        bookingId: row.id,
        paymentId: payment.id,
        amountPaise: booking.refund.amountPaise,
        providerRef: `demo_refund_${booking.code}`,
        status: booking.refund.status,
      },
    });
  }

  if (booking.review) {
    await prisma.review.create({
      data: {
        bookingId: row.id,
        userId: user.id,
        rating: booking.review.rating,
        body: booking.review.body,
        status: booking.review.reviewStatus ?? ReviewStatus.PUBLISHED,
      },
    });
  }

  for (const event of booking.eventChain) {
    await prisma.bookingEvent.create({
      data: { bookingId: row.id, fromStatus: event.from, toStatus: event.to, actorId: user.id, createdAt },
    });
  }

  return { id: row.id, bookingId: row.id, venueName: '' };
}

interface UserContext {
  id: string;
  phoneE164: string;
  name: string;
}

async function seedUsersAndBookings(slotCache: Map<string, DemoSlot>): Promise<void> {
  console.log('Seeding demo users, bookings, payments, saved venues, notifications, and support tickets...');
  const users: UserContext[] = [];
  for (const seed of DEMO_USERS) {
    const user = await prisma.user.create({
      data: {
        phoneE164: seed.phoneE164,
        name: seed.name,
        status: 'ACTIVE',
        preferences: { theme: seed.phoneE164 === DEMO_USERS[0].phoneE164 ? 'dark' : 'light' },
      },
    });
    users.push({ id: user.id, phoneE164: seed.phoneE164, name: seed.name });
  }
  const [demo, priya, rahul, sneha] = users;

  const half = (key: string) => {
    const slot = slotCache.get(key);
    if (!slot) throw new Error(`Missing slot for key ${key}`);
    return slot.pricePaise / BigInt(2);
  };

  const bookingsByUser: Array<{ user: UserContext; bookings: BookingSeed[] }> = [
    {
      user: demo,
      bookings: [
        {
          code: 'ACT-DEMO0001',
          status: BookingStatus.CONFIRMED,
          slotKey: 'arena|football_turf|1|18',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          createdAt: 2,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
          ],
        },
        {
          code: 'ACT-DEMO0002',
          status: BookingStatus.COMPLETED,
          slotKey: 'arena|football_turf|-3|7',
          quantity: 2,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          review: { rating: 5, body: 'Great turf, well maintained and good parking.' },
          createdAt: 5,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'COMPLETED' },
          ],
        },
        {
          code: 'ACT-DEMO0003',
          status: BookingStatus.CANCELLED,
          slotKey: 'arena|football_turf|-1|19',
          quantity: 1,
          attemptStatus: AttemptStatus.RELEASED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.REFUND_PENDING,
          refund: { amountPaise: half('arena|football_turf|-1|19'), status: RefundStatus.PENDING },
          createdAt: 3,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'CANCELLED' },
          ],
        },
        {
          code: 'ACT-DEMO0004',
          status: BookingStatus.COMPLETED,
          slotKey: 'smash|badminton|-2|9',
          quantity: 2,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          review: { rating: 4, body: 'Lovely wooden courts and friendly staff.', reviewStatus: ReviewStatus.PENDING },
          createdAt: 8,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'COMPLETED' },
          ],
        },
        {
          code: 'ACT-DEMO0005',
          status: BookingStatus.CONFIRMED,
          slotKey: 'pulse|gym|2|8',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          createdAt: 1,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
          ],
        },
        {
          code: 'ACT-DEMO0006',
          status: BookingStatus.CONFIRMED,
          slotKey: 'spark|tennis|3|17',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          rescheduleCount: 1,
          createdAt: 4,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'RESCHEDULED' },
          ],
        },
        {
          code: 'ACT-DEMO0007',
          status: BookingStatus.PENDING_PAYMENT,
          slotKey: 'greenlawn|cricket_turf|4|10',
          quantity: 1,
          attemptStatus: AttemptStatus.HELD,
          attemptExpiry: 'future',
          paymentStatus: PaymentStatus.CREATED,
          createdAt: 1,
          eventChain: [{ from: 'CREATED', to: 'PENDING_PAYMENT' }],
        },
        {
          code: 'ACT-DEMO0008',
          status: BookingStatus.CANCELLED,
          slotKey: 'metro|snooker|-3|13',
          quantity: 1,
          attemptStatus: AttemptStatus.RELEASED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.REFUNDED,
          refund: { amountPaise: half('metro|snooker|-3|13'), status: RefundStatus.PROCESSED },
          createdAt: 6,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'CANCELLED' },
          ],
        },
      ],
    },
    {
      user: priya,
      bookings: [
        {
          code: 'ACT-PRIYA0001',
          status: BookingStatus.CONFIRMED,
          slotKey: 'spark|tennis|0|17',
          quantity: 2,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          createdAt: 2,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
          ],
        },
        {
          code: 'ACT-PRIYA0002',
          status: BookingStatus.CONFIRMED,
          slotKey: 'greenlawn|cricket_turf|2|18',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          createdAt: 3,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
          ],
        },
        {
          code: 'ACT-PRIYA0003',
          status: BookingStatus.COMPLETED,
          slotKey: 'metro|snooker|-3|13',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          review: { rating: 4, body: 'Neat tables and good lighting.' },
          createdAt: 9,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'COMPLETED' },
          ],
        },
        {
          code: 'ACT-PRIYA0004',
          status: BookingStatus.CANCELLED,
          slotKey: 'arena|swimming|-2|10',
          quantity: 1,
          attemptStatus: AttemptStatus.RELEASED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.REFUND_PENDING,
          refund: { amountPaise: half('arena|swimming|-2|10'), status: RefundStatus.PENDING },
          createdAt: 5,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'CANCELLED' },
          ],
        },
        {
          code: 'ACT-PRIYA0005',
          status: BookingStatus.CONFIRMED,
          slotKey: 'pulse|yoga|1|7',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          rescheduleCount: 1,
          createdAt: 4,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'RESCHEDULED' },
          ],
        },
      ],
    },
    {
      user: rahul,
      bookings: [
        {
          code: 'ACT-RAHUL0001',
          status: BookingStatus.CONFIRMED,
          slotKey: 'smash|badminton|2|19',
          quantity: 2,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          createdAt: 2,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
          ],
        },
        {
          code: 'ACT-RAHUL0002',
          status: BookingStatus.COMPLETED,
          slotKey: 'metro|pool|-1|20',
          quantity: 2,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          review: { rating: 3, body: 'Good tables but the area was a bit crowded.' },
          createdAt: 10,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'COMPLETED' },
          ],
        },
        {
          code: 'ACT-RAHUL0003',
          status: BookingStatus.CANCELLED,
          slotKey: 'greenlawn|hockey|-3|16',
          quantity: 1,
          attemptStatus: AttemptStatus.RELEASED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.REFUNDED,
          refund: { amountPaise: half('greenlawn|hockey|-3|16'), status: RefundStatus.PROCESSED },
          createdAt: 7,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'CANCELLED' },
          ],
        },
        {
          code: 'ACT-RAHUL0004',
          status: BookingStatus.PENDING_PAYMENT,
          slotKey: 'delta|boxing|3|18',
          quantity: 1,
          attemptStatus: AttemptStatus.HELD,
          attemptExpiry: 'future',
          paymentStatus: PaymentStatus.CREATED,
          createdAt: 1,
          eventChain: [{ from: 'CREATED', to: 'PENDING_PAYMENT' }],
        },
      ],
    },
    {
      user: sneha,
      bookings: [
        {
          code: 'ACT-SNEHA0001',
          status: BookingStatus.CONFIRMED,
          slotKey: 'pulse|crossfit|4|18',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          createdAt: 2,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
          ],
        },
        {
          code: 'ACT-SNEHA0002',
          status: BookingStatus.COMPLETED,
          slotKey: 'ocean|swimming|-2|8',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          review: { rating: 5, body: 'Clean pool, great coaching staff.' },
          createdAt: 6,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'COMPLETED' },
          ],
        },
        {
          code: 'ACT-SNEHA0003',
          status: BookingStatus.COMPLETED,
          slotKey: 'bullz|cricket_nets|-1|14',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          review: { rating: 3, body: 'Nets are okay, parking is a bit far.', reviewStatus: ReviewStatus.PENDING },
          createdAt: 12,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'COMPLETED' },
          ],
        },
        {
          code: 'ACT-SNEHA0004',
          status: BookingStatus.CANCELLED,
          slotKey: 'gladiator|badminton|-3|19',
          quantity: 2,
          attemptStatus: AttemptStatus.RELEASED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.REFUND_PENDING,
          refund: { amountPaise: half('gladiator|badminton|-3|19'), status: RefundStatus.PENDING },
          createdAt: 7,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'CANCELLED' },
          ],
        },
        {
          code: 'ACT-SNEHA0005',
          status: BookingStatus.CONFIRMED,
          slotKey: 'zen|yoga|2|9',
          quantity: 1,
          attemptStatus: AttemptStatus.CONSUMED,
          attemptExpiry: 'past',
          paymentStatus: PaymentStatus.CAPTURED,
          rescheduleCount: 1,
          createdAt: 3,
          eventChain: [
            { from: 'CREATED', to: 'PENDING_PAYMENT' },
            { from: 'PENDING_PAYMENT', to: 'CONFIRMED' },
            { from: 'CONFIRMED', to: 'RESCHEDULED' },
          ],
        },
      ],
    },
  ];

  const venueNames: Record<string, string> = {};
  for (const seed of venueSeeds) {
    venueNames[seed.key] = seed.name;
  }

  for (const entry of bookingsByUser) {
    for (const booking of entry.bookings) {
      await createBooking(entry.user, booking, slotCache);
    }
  }

  // Saved venues: demo saves the first few, others save a mix.
  const venues = await prisma.venue.findMany({ orderBy: { name: 'asc' }, select: { id: true } });
  const save = async (userId: string, index: number) => {
    if (index < venues.length) {
      await prisma.savedVenue.upsert({ where: { userId_venueId: { userId, venueId: venues[index].id } }, create: { userId, venueId: venues[index].id }, update: {} });
    }
  };
  await save(demo.id, 0);
  await save(demo.id, 2);
  await save(demo.id, 5);
  await save(priya.id, 1);
  await save(rahul.id, 3);
  await save(sneha.id, 4);

  // Notifications for the demo user.
  const demoConfirmed = await prisma.booking.findUniqueOrThrow({ where: { publicCode: 'ACT-DEMO0001' }, select: { id: true } });
  const demoCancelled = await prisma.booking.findUniqueOrThrow({ where: { publicCode: 'ACT-DEMO0003' }, select: { id: true } });
  const demoCompleted = await prisma.booking.findUniqueOrThrow({ where: { publicCode: 'ACT-DEMO0002' }, select: { id: true } });
  const demoRescheduled = await prisma.booking.findUniqueOrThrow({ where: { publicCode: 'ACT-DEMO0006' }, select: { id: true } });
  const now = new Date();
  await prisma.notification.createMany({
    data: [
      { userId: demo.id, bookingId: demoConfirmed.id, type: 'booking', title: 'Booking Confirmed', body: `Your Football Turf slot at ${venueNames['arena']} is confirmed. See you there!`, status: NotificationStatus.SENT, createdAt: new Date(now.getTime() - 2 * 24 * 3600 * 1000), sentAt: new Date(now.getTime() - 2 * 24 * 3600 * 1000) },
      { userId: demo.id, bookingId: demoConfirmed.id, type: 'payment', title: 'Payment Received', body: 'We received your payment. Your booking is confirmed.', status: NotificationStatus.SENT, createdAt: new Date(now.getTime() - 2 * 24 * 3600 * 1000), sentAt: new Date(now.getTime() - 2 * 24 * 3600 * 1000) },
      { userId: demo.id, bookingId: demoRescheduled.id, type: 'booking', title: 'Booking Rescheduled', body: 'Your Tennis slot has been rescheduled. Tap to view the new time.', status: NotificationStatus.SENT, createdAt: new Date(now.getTime() - 1 * 24 * 3600 * 1000), sentAt: new Date(now.getTime() - 1 * 24 * 3600 * 1000) },
      { userId: demo.id, bookingId: demoCancelled.id, type: 'refund', title: 'Refund Initiated', body: 'Your refund for the cancelled booking is being processed.', status: NotificationStatus.SENT, createdAt: new Date(now.getTime() - 1 * 24 * 3600 * 1000), sentAt: new Date(now.getTime() - 1 * 24 * 3600 * 1000) },
      { userId: demo.id, bookingId: demoCompleted.id, type: 'general', title: 'How was your session?', body: 'Rate your recent booking and help other players choose better venues.', status: NotificationStatus.PENDING, createdAt: now },
      { userId: demo.id, type: 'offer', title: '20% OFF Your Next Booking', body: 'Use code ACTIV20 on your next booking to save big.', status: NotificationStatus.SENT, createdAt: new Date(now.getTime() - 3 * 24 * 3600 * 1000), sentAt: new Date(now.getTime() - 3 * 24 * 3600 * 1000) },
      { userId: demo.id, type: 'offer', title: 'Flat ₹100 Off This Week', body: 'Use code WELCOME100 for a flat ₹100 off on any turf booking.', status: NotificationStatus.PENDING, createdAt: now },
      { userId: demo.id, type: 'alert', title: 'Payment Retry Needed', body: 'Your payment could not be completed. Please retry before the slot is released.', status: NotificationStatus.FAILED, createdAt: new Date(now.getTime() - 4 * 24 * 3600 * 1000) },
    ],
  });

  // Support tickets for the demo user.
  await prisma.supportTicket.createMany({
    data: [
      { userId: demo.id, bookingId: demoCompleted.id, subject: 'Turf quality feedback', message: 'The football turf had a worn patch near the centre circle.', status: TicketStatus.RESOLVED, createdAt: new Date(now.getTime() - 4 * 24 * 3600 * 1000) },
      { userId: demo.id, bookingId: demoCancelled.id, subject: 'Refund not yet received', message: 'I cancelled my booking 3 days ago but the refund has not arrived.', status: TicketStatus.IN_PROGRESS, createdAt: new Date(now.getTime() - 2 * 24 * 3600 * 1000) },
      { userId: demo.id, subject: 'How to book for a group?', message: 'Can I book a single slot and add friends at the venue?', status: TicketStatus.OPEN, createdAt: now },
    ],
  });
  console.log('Seeded demo users and bookings.');
}

async function seedContent(): Promise<void> {
  console.log('Seeding content documents and FAQs...');
  const now = new Date();
  const privacyPolicyBody = [
    'At ACTIV, we respect your privacy. This Privacy Policy explains how we collect, use, and protect your data.',
    '',
    '1. Information We Collect',
    '- Personal Information: Name, email, phone number, Aadhaar/PAN (for verification).',
    '- Venue Information: Venue name, address, operating hours, amenities, photos.',
    '- Usage Data: Bookings, activity logs, preferences.',
    '- Device Data: IP address, device type, browser/app version.',
    '',
    '2. How we use your information',
    '- To onboard and verify partners.',
    '- To manage bookings, payments, and notifications.',
    '- To improve features and provide personalized experiences.',
    '- To comply with legal obligations.',
    '',
    '3. Data Sharing',
    '- Shared with payment providers, verification agencies, and analytics services.',
    '- We do not sell your personal data to third parties.',
    '',
    '4. Cancellations & Refunds',
    "- Customer cancellations and refunds will follow ACTIV's cancellation policy, available in the app.",
    '- Partners must honor bookings unless canceled through the system.',
    '',
    '5. Data & Content',
    '- By uploading photos, descriptions, or documents, partners grant ACTIV a non-exclusive license to display them within the platform.',
    '- Misuse of the platform, fraudulent documents, or misleading information may result in suspension.',
    '',
    '6. Liability',
    '- ACTIV acts as a technology platform and is not liable for injuries, damages, or disputes arising within venues.',
    '- Partners must ensure adequate insurance coverage and legal compliance.',
    '',
    '7. Termination',
    '- ACTIV reserves the right to suspend or terminate access if Terms are violated.',
    '- Partners may request deACTIVation at any time via the app.',
  ].join('\n');
  await prisma.contentDocument.createMany({
    data: [
      {
        type: 'privacy-policy',
        version: 'v1',
        title: 'Privacy Policy',
        body: privacyPolicyBody,
        status: ContentStatus.PUBLISHED,
        publishedAt: now,
      },
      {
        type: 'terms-of-service',
        version: 'v1',
        title: 'Terms of Service',
        body: 'By using ACTIV you agree to fair use of venues, timely cancellations, and adherence to venue rules. ACTIV is not liable for personal injury during activities.',
        status: ContentStatus.PUBLISHED,
        publishedAt: now,
      },
      {
        type: 'cancellation-policy',
        version: 'v1',
        title: 'Cancellation Policy',
        body: 'Free cancellation up to 12 hours before start. 50% refund between 12h and 3h before start. No refund within 3 hours of the slot start time.',
        status: ContentStatus.PUBLISHED,
        publishedAt: now,
      },
      {
        type: 'refund-policy',
        version: 'v1',
        title: 'Refund Policy',
        body: 'Refunds are processed to the original payment method within 3–7 working days after approval. Wallet credits are refunded instantly.',
        status: ContentStatus.PUBLISHED,
        publishedAt: now,
      },
      {
        type: 'booking-policy',
        version: 'v1',
        title: 'Booking Policy',
        body: 'A booking can be rescheduled once. Rescheduling is allowed up to 30 minutes before the slot start. Only slots of the same value can be selected.',
        status: ContentStatus.PUBLISHED,
        publishedAt: now,
      },
    ],
    skipDuplicates: true,
  });
  await prisma.contentDocument.updateMany({
    where: { type: 'privacy-policy', version: 'v1' },
    data: { title: 'Privacy Policy', body: privacyPolicyBody, status: ContentStatus.PUBLISHED, publishedAt: now },
  });

  await prisma.faq.createMany({
    data: [
      { question: 'How do I book a sports venue?', answer: 'Browse venues, select your preferred date and time, then confirm your booking through the app.', sortOrder: 1, status: ContentStatus.PUBLISHED, publishedAt: now },
      { question: 'Can I cancel my booking?', answer: 'Yes, you can cancel eligible bookings from My Bookings. Refunds depend on the venue cancellation policy.', sortOrder: 2, status: ContentStatus.PUBLISHED, publishedAt: now },
      { question: 'Can I reschedule my booking?', answer: 'Yes, confirmed bookings can be rescheduled once before the slot starts, subject to availability.', sortOrder: 3, status: ContentStatus.PUBLISHED, publishedAt: now },
      { question: 'When will I receive my booking confirmation?', answer: 'Your booking confirmation appears in the app as soon as payment is completed successfully.', sortOrder: 4, status: ContentStatus.PUBLISHED, publishedAt: now },
      { question: 'What payment methods are accepted?', answer: 'You can pay using UPI, cards, wallets, and other supported online payment methods at checkout.', sortOrder: 5, status: ContentStatus.PUBLISHED, publishedAt: now },
    ],
    skipDuplicates: true,
  });
  console.log('Seeded content.');
}

async function main(): Promise<void> {
  await cleanupDemoData();
  const slotCache = await seedCatalog();
  await seedCoupons();
  await seedUsersAndBookings(slotCache);
  await seedContent();
  const venueCount = await prisma.venue.count();
  const activityCount = await prisma.activity.count();
  const userCount = await prisma.user.count();
  const bookingCount = await prisma.booking.count();
  const slotCount = await prisma.slot.count();
  console.log(`Seeded ${activityCount} activities, ${venueCount} venues, ${slotCount} slots, ${userCount} users, ${bookingCount} bookings, coupons, notifications, tickets & content.`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
