# Deployment Guide

This document outlines how to run the ACTIV backend locally for development and how to deploy it to a production environment.

## 1. Local Development

### Prerequisites
- Node.js (v20+)
- Docker Desktop (for running PostgreSQL and Redis locally)

### Setup
1. **Clone the repository.**
2. **Install dependencies:** `npm install`
3. **Set up Environment Variables:** Create a `.env` file in the root based on `.env.example`. Make sure you have the MSG91 keys, Razorpay keys, and database connection strings.
4. **Start local database & Redis:** (Assuming a docker-compose file is present, or just run them manually).
5. **Run Prisma Migrations:**
   ```bash
   npx prisma generate
   npx prisma db push
   ```
6. **Start the server:**
   ```bash
   npm run start:dev
   ```
7. The API will be available at `http://localhost:3000/api/v1` and the Swagger Docs at `http://localhost:3000/api/docs`.

## 2. Production Deployment (Neevcloud)

The backend is designed to be hosted on Neevcloud using Docker containers.

### High-Level Architecture
- **Web Server:** A reverse proxy (like Nginx or Caddy) to handle HTTPS and route traffic to the Node.js process.
- **Node Process:** Runs the compiled NestJS application via `npm run start:prod` (or `node dist/main.js`).
- **Database:** A managed PostgreSQL instance or a self-hosted PostgreSQL container with persistent volumes.
- **Cache:** A Redis container for caching and rate limiting.

### Build Steps for CI/CD
1. Set up secrets (environment variables) in your CI pipeline.
2. Build the app:
   ```bash
   npm run build
   ```
3. Generate Prisma client:
   ```bash
   npx prisma generate
   ```
4. Run migrations (only if using `migrate deploy` instead of `db push`):
   ```bash
   npx prisma migrate deploy
   ```
5. Start the production process (recommended to use PM2 or Docker).

### File Uploads & Media
Currently, media files (like banners and icons) are stored locally in the `media/` folder. In production:
- Ensure the `media/` folder is mapped to a persistent Docker Volume so uploads are not lost during container restarts.
- Future enhancement: Migrate to an Object Storage service (like AWS S3) using the `OBJECT_STORAGE_BUCKET` configuration for better scalability.
