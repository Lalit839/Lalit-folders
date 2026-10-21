import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { AdminUsersService } from '../../src/admin/admin-users.service';
import { AuthService } from '../../src/auth/auth.service';

const enabled = process.env.RUN_INTEGRATION_TESTS === '1';

(enabled ? describe : describe.skip)('auth to admin users synchronization (PostgreSQL)', () => {
  const prisma = new PrismaClient();
  const suffix = randomUUID().replace(/-/g, '').slice(0, 9);
  const phone = `+919${suffix}`;
  const fullName = `Sync User ${suffix}`;
  const previousDemoOtp = process.env.DEMO_OTP;
  let auth: AuthService;
  let adminUsers: AdminUsersService;
  let createdUserId: string | undefined;

  beforeAll(async () => {
    process.env.DEMO_OTP = 'true';
    const config = new ConfigService({
      JWT_ACCESS_SECRET: 'integration-access-secret-32chars',
      JWT_REFRESH_SECRET: 'integration-refresh-secret-32chars',
    });
    auth = new AuthService(
      prisma as never,
      new JwtService({
        secret: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        signOptions: {
          expiresIn: '10m',
          issuer: 'activ-api',
          audience: 'activ-mobile',
        },
      }),
      config,
      { assertAllowed: jest.fn().mockResolvedValue(undefined) } as never,
    );
    adminUsers = new AdminUsersService(prisma as never);
  });

  afterAll(async () => {
    if (createdUserId) {
      await prisma.session.deleteMany({ where: { userId: createdUserId } });
      await prisma.user.deleteMany({ where: { id: createdUserId } });
    } else {
      await prisma.user.deleteMany({ where: { phoneE164: phone } });
    }
    await prisma.otpChallenge.deleteMany({ where: { phoneE164: phone } });
    if (previousDemoOtp === undefined) delete process.env.DEMO_OTP;
    else process.env.DEMO_OTP = previousDemoOtp;
    await prisma.$disconnect();
  });

  it('creates the mobile user, stores the profile name, and exposes it to admin users list', async () => {
    await auth.requestOtp(phone, '127.0.0.1');
    await auth.verifyOtp(phone, '0000', '127.0.0.1');

    const created = await prisma.user.findUniqueOrThrow({
      where: { phoneE164: phone },
      select: { id: true },
    });
    createdUserId = created.id;

    await auth.updateProfile(createdUserId, { name: fullName });

    const adminList = await adminUsers.list({ search: phone, page: 1, limit: 10 });
    expect(adminList.total).toBe(1);
    expect(adminList.items[0]).toMatchObject({
      id: createdUserId,
      phoneE164: phone,
      name: fullName,
      status: 'ACTIVE',
    });
  });
});
