FROM node:20-bookworm-slim AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
RUN npm ci
COPY tsconfig.json nest-cli.json ./
COPY prisma ./prisma
COPY src ./src
RUN npx prisma generate && npm run build && npx tsc prisma/seed.ts --outDir dist-seed --module commonjs --moduleResolution node --target es2020 --esModuleInterop --skipLibCheck && npm prune --omit=dev

FROM node:20-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
RUN useradd --system --uid 1001 appuser
COPY --from=build --chown=appuser:appuser /app/package*.json ./
COPY --from=build --chown=appuser:appuser /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appuser /app/dist ./dist
COPY --from=build --chown=appuser:appuser /app/dist-seed ./dist-seed
COPY --from=build --chown=appuser:appuser /app/prisma ./prisma
COPY --chown=appuser:appuser media ./media
RUN npm install --no-save prisma@6.19.3 && ./node_modules/.bin/prisma generate
ENV HOME=/tmp
USER appuser
EXPOSE 3000
CMD ["sh", "-c", "./node_modules/.bin/prisma migrate deploy && if [ \"$RUN_SEED\" = \"true\" ]; then node dist-seed/seed.js; fi && node dist/main.js"]
