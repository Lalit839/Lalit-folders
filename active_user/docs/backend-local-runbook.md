# ACTIV Backend Local Runbook

## Start Dependencies

```text
docker compose up -d
```

## Configure and Start API

```text
copy .env.example .env
npm ci
npm run db:generate
npm run db:deploy
npm run db:seed
npm run start:dev
```

API base URL: `http://localhost:3000/api/v1`

Swagger: `http://localhost:3000/api/docs`

## Verification

```text
npm run lint
npm run typecheck
npm run build
npm test -- --runInBand
set RUN_INTEGRATION_TESTS=1 && npm run test:integration
```

The seed command creates one published demo venue, activity, facility and future slot. It must only be used against a local or isolated development database.

## Production Gate

Do not deploy until provider credentials, refund/retention decisions, staging migrations, backup restore, payment webhook, duplicate booking and security tests are completed.
