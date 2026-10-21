# ACTIV Flutter Mock App Data

Local mock app data is disabled. The app should read catalog, venue, booking, offer, and profile data from the configured backend/Supabase database.

## Enable

Keep this disabled in `.env.development` and `.env.production`:

```env
MOCK_APP_DATA=false
```

Mock scenarios should not be used for app builds:

```env
MOCK_APP_DATA_SCENARIO=success
MOCK_APP_DATA_SCENARIO=delay
MOCK_APP_DATA_SCENARIO=empty
MOCK_APP_DATA_SCENARIO=error
```

## Real Backend Calls

These always use the configured NestJS backend:

- OTP request and verification.
- Access and refresh tokens.
- Logout and delete-account requests.
- Profile fetch and profile updates.
- Onboarding profile completion.
- Device registration for push notifications.

## App Data Source

All app sections should use the configured backend API, which reads from the Supabase database.

## Audited Screens

- Auth: login, OTP, name/profile completion.
- Home and discovery.
- Venue search, filters, venue details.
- Slot booking, review booking, coupons, payment success/failure.
- My bookings, booking details, cancellation and reschedule.
- Saved venues.
- Notifications and calendar.
- Profile, edit profile, preferences, support, FAQs, legal/policies, rate ACTIV.

## Current Limits

- Physical permission flows, push delivery and real payment gateway behavior still require device/backend testing.
