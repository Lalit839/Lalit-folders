# ACTIV Backend

ACTIV backend ka planned implementation NestJS modular monolith hai. Is folder mein production code add hoga; `docs/` mein approved contracts aur design decisions maintained rahenge.

## Build Order

1. Identity and sessions
2. Catalog and partner-scoped inventory
3. Availability, holds and booking transaction
4. Razorpay order/webhook/reconciliation
5. Booking lifecycle, refunds and outbox notifications
6. Reviews, saved venues, calendar and support

## Required Environment Variables

```text
NODE_ENV=development|staging|production
PORT=3000
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_ACCESS_SECRET=replace-with-secret-manager-value
JWT_REFRESH_SECRET=replace-with-secret-manager-value
RAZORPAY_KEY_ID=...
RAZORPAY_KEY_SECRET=...
RAZORPAY_WEBHOOK_SECRET=...
OTP_PROVIDER_API_KEY=...
OBJECT_STORAGE_BUCKET=...
```

Never commit real values. Staging and production must use separate database, Redis, storage and payment credentials.

## API Contract

When the API is running outside production, Swagger UI is available at `/api/docs` and the generated OpenAPI JSON at `/api/docs-json`. Swagger is disabled in production. The design contract remains in `../docs/api-documentation.md`; implementation changes must update both the decorators and that document.

## Local Infrastructure

Use PostgreSQL and Redis from a local Docker Compose setup. Run migrations before starting the API. Database invariants are versioned in Prisma migrations. Use `npm run db:deploy` in staging/production; integration tests must use an isolated test database and must never point at staging or production.

## Local Start

```text
docker compose up -d
npm ci
copy .env.example .env
npm run db:generate
npm run db:migrate
npm run start:dev
```

The production image uses a multi-stage build and runs as a non-root user. It requires externally managed PostgreSQL, Redis and secrets; production must not use the local compose credentials.

## Definition Of Ready

Implementation starts after API/database documents are reviewed and the open product decisions in `docs/decisions-and-open-items.md` have owners. No endpoint is considered production-ready without validation, authorization, idempotency behavior where relevant, audit behavior and tests.
