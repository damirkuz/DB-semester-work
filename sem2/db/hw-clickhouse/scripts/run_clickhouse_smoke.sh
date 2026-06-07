#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

docker compose up -d clickhouse

for _ in {1..30}; do
  if docker compose exec -T clickhouse clickhouse-client --password clickhouse --query "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker compose exec -T clickhouse clickhouse-client --password clickhouse --multiquery \
  < clickhouse/01_create_and_seed.sql
docker compose exec -T clickhouse clickhouse-client --password clickhouse --multiquery \
  < clickhouse/smoke_test.sql
