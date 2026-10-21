# Architecture Decision Log (ADR)

This document tracks significant architectural decisions made during the development of the ACTIV backend.

## ADR-001: Framework Choice
**Date:** Initial Setup
**Status:** Accepted
**Decision:** We chose **NestJS** over raw Express or Fastify because of its strong TypeScript support, opinionated modular structure, and built-in dependency injection. This allows the backend to scale cleanly as domain complexity grows (Bookings, Payments, Users, Admin).

## ADR-002: Database & ORM
**Date:** Initial Setup
**Status:** Accepted
**Decision:** We selected **PostgreSQL** for its robust relational data integrity and ACID compliance, which is critical for handling bookings and financial transactions. We paired it with **Prisma ORM** for type-safe database queries and intuitive schema migrations.

## ADR-003: Payment Gateway Integration
**Date:** Payment Module Setup
**Status:** Accepted
**Decision:** **Razorpay** was chosen as the primary payment gateway for the Indian market. We implemented Razorpay's webhook system to asynchronously confirm payments, ensuring that users aren't left waiting on synchronous network calls during checkout. A fallback polling mechanism exists if webhooks fail.

## ADR-004: OTP Authentication
**Date:** Auth Module Setup
**Status:** Accepted
**Decision:** Instead of using Firebase Phone Auth, we chose **MSG91** as the OTP provider. This gives us finer control over the SMS delivery, template customization, and potential expansion into WhatsApp OTP channels without vendor lock-in.

## ADR-005: Idempotency in Bookings
**Date:** Bookings Module Setup
**Status:** Accepted
**Decision:** To prevent users from being charged multiple times if they double-tap the checkout button or if a network error occurs, we require an `idempotencyKey` on the `POST /api/v1/bookings/checkout` endpoint.

## ADR-006: Audit Trails
**Date:** Admin Upgrades Phase
**Status:** Accepted
**Decision:** We implemented a generic `AuditEvent` table that records state changes for sensitive operations (e.g., Refund Processing, User Deletion, Policy Updates). This ensures accountability for all Admin actions.
