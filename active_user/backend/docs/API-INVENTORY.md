# API Inventory

The ACTIV backend is built around domain-specific modules. All APIs are prefixed with `/api/v1`.

## Swagger / OpenAPI

The easiest way to explore and test the APIs is through the built-in Swagger UI.
When the server is running in development mode, simply navigate to:

```
http://localhost:3000/api/docs
```

This interface is automatically generated from the NestJS controllers and DTOs. It allows you to:
- See the exact payload schema required for every endpoint.
- Authenticate (using the `Authorize` button at the top right) by pasting your JWT Bearer token.
- Test endpoints directly from the browser.

## High-Level API Modules

### 1. Auth Module (`/api/v1/auth`)
Handles user authentication via OTP. 
- **Providers:** MSG91
- **Key Endpoints:** `/request-otp`, `/verify-otp`, `/refresh`, `/logout`

### 2. Admin Module (`/api/v1/admin`)
Restricted to users with the `ADMIN` role. Powers the backend admin dashboard.
- **Key Endpoints:** `/dashboard`, `/users`, `/bookings`, `/payments`, `/refunds`, `/feature-flags`, `/audit-logs`

### 3. Bookings Module (`/api/v1/bookings`)
Manages the lifecycle of a venue booking (creating attempts, calculating prices, applying coupons, and processing checkout).
- **Idempotency:** The `/checkout` endpoint requires an `idempotencyKey` header to prevent double bookings during network retries.

### 4. Catalog Module (`/api/v1/catalog`)
Provides read-only endpoints for the mobile app to browse cities, sports activities, venues, and time slots.

### 5. Media Module (`/api/v1/media`)
Serves static assets like venue icons, amenity icons, and promotional banners.
- **Key Endpoints:** `/banners/:name`, `/icons/:name`

### 6. Notifications Module (`/api/v1/notifications`)
Handles push notifications to mobile devices.
- **Providers:** Firebase Cloud Messaging (FCM).
- **Key Endpoints:** `/devices/register`
