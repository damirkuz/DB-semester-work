#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

docker compose up -d mongodb

for _ in {1..30}; do
  if docker compose exec -T mongodb \
    mongosh "mongodb://root:root@localhost:27017/admin" \
    --eval "db.runCommand({ ping: 1 })" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker compose exec -T mongodb \
  mongosh "mongodb://root:root@localhost:27017/admin" \
  --file /homework/mongo/smoke_test.js
