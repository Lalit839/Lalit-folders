import { PrismaClient } from '@prisma/client';
import { randomBytes, scryptSync } from 'node:crypto';

const prisma = new PrismaClient();

async function main() {
  const args = process.argv.slice(2);
  const emailArg = args.find((a) => a.startsWith('--email='));
  const passwordArg = args.find((a) => a.startsWith('--password='));
  const email = emailArg?.split('=')[1];
  const password = passwordArg?.split('=')[1];
  if (!email || !password) {
    console.error('Usage: npm run admin:create -- --email=admin@example.com --password=Secret123!');
    process.exit(1);
  }
  if (password.length < 8) {
    console.error('Password must be at least 8 characters');
    process.exit(1);
  }
  const salt = process.env.JWT_REFRESH_SECRET?.slice(0, 16) ?? 'change-me-admin-salt';
  const passwordHash = scryptSync(password, salt, 32).toString('hex');

  const existing = await prisma.user.findFirst({ where: { email: email.trim().toLowerCase() } });
  const user = existing
    ? await prisma.user.update({
        where: { id: existing.id },
        data: { isAdmin: true, passwordHash, status: 'ACTIVE', email: email.trim().toLowerCase() },
        select: { id: true, email: true, isAdmin: true },
      })
    : await prisma.user.create({
        data: {
          phoneE164: `+91-admin-${randomBytes(6).toString('hex')}`,
          email: email.trim().toLowerCase(),
          name: 'Admin',
          isAdmin: true,
          passwordHash,
          status: 'ACTIVE',
        },
        select: { id: true, email: true, isAdmin: true },
      });
  console.log(`Admin ready: ${user.email} (isAdmin=${user.isAdmin})`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());