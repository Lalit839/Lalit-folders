# ACTIV Backend Documentation

Welcome to the backend repository for the **ACTIV** platform. This NestJS application serves as the core API for both the user-facing mobile app and the admin web dashboard.

## Tech Stack
- **Framework:** [NestJS](https://nestjs.com/)
- **Database:** PostgreSQL with [Prisma ORM](https://www.prisma.io/)
- **Caching & Queues:** Redis (via `ioredis`)
- **Payments:** Razorpay
- **Notifications:** MSG91 (OTP/WhatsApp) and Firebase Cloud Messaging (FCM)

## Documentation Index

Please refer to the following documents for detailed information on specific areas:

1. **[API Inventory & OpenAPI](./API-INVENTORY.md)** - Details on how to access the Swagger UI and a high-level overview of the API modules.
2. **[Architecture Decision Log](./DECISION-LOG.md)** - A log of all major technical and architectural decisions made during development (ADRs).
3. **[Deployment Guide](./DEPLOYMENT.md)** - Instructions for running the app locally, configuring the environment, and deploying to cloud providers like Neevcloud.

## Core Principles

- **Security First:** All sensitive endpoints are guarded using JWT-based authentication and role-based access control (RBAC). 
- **Idempotency:** Payment and booking flows leverage idempotent designs to prevent double charging and ensure data consistency.
- **Audit Trails:** Crucial business actions (refunds, role changes, policy updates) automatically generate audit logs.
