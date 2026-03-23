#!/usr/bin/env bash
set -euo pipefail

export PGPASSWORD='replpass'

until pg_isready -h pg-primary -U postgres; do
  sleep 2
done

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  rm -rf "${PGDATA:?}"/*

  pg_basebackup \
    -h pg-primary \
    -U replicator \
    -D "$PGDATA" \
    -Fp \
    -Xs \
    -P \
    -R \
    -C \
    -S "$REPLICATION_SLOT"

  echo "primary_slot_name = '$REPLICATION_SLOT'" >> "$PGDATA/postgresql.auto.conf"
fi

exec docker-entrypoint.sh postgres -c hot_standby=on
