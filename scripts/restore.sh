#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
BACKUP_DIR="$1"
[ -n "$BACKUP_DIR" ] || { echo "Usage: ./scripts/restore.sh backups/backup-YYYY-MM-DD-HHMM"; exit 1; }
[ -d "$BACKUP_DIR" ] || { echo "ERROR: backup directory not found"; exit 1; }
[ -s "$BACKUP_DIR/database.sql.gz" ] || { echo "ERROR: database.sql.gz missing"; exit 1; }
[ -s "$BACKUP_DIR/uploads.tar.gz" ] || { echo "ERROR: uploads.tar.gz missing"; exit 1; }
set -a
. ./.env
set +a
gzip -t "$BACKUP_DIR/database.sql.gz"
tar -tzf "$BACKUP_DIR/uploads.tar.gz" >/dev/null
docker compose up -d --wait
for i in $(seq 1 60); do
  if docker compose exec -T db mysqladmin ping -h 127.0.0.1 -u root -p"$DB_ROOT_PASSWORD" --silent >/dev/null 2>&1; then break; fi
  [ "$i" -eq 60 ] && { echo "ERROR: database not ready"; exit 1; }
  sleep 2
done
rm -rf app/wp-content/uploads/*
tar -C app/wp-content -xzf "$BACKUP_DIR/uploads.tar.gz"
gunzip -c "$BACKUP_DIR/database.sql.gz" | docker compose exec -T db sh -c 'exec mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'
docker compose up -d --wait
./scripts/verify.sh
