#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Checking docker"
command -v docker >/dev/null || (echo "docker not installed"; exit 1)

echo "==> Building and starting production stack"
docker compose -f docker-compose.prod.yml up -d --build

echo "==> Waiting for backend health"
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/health || true)
  if [ "$code" = "200" ]; then
    echo "Backend healthy (HTTP 200)"
    exit 0
  fi
  sleep 5
done

echo "Backend did not become healthy in time. Check: docker compose -f docker-compose.prod.yml logs backend"
exit 1