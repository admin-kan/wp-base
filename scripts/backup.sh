#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] || { echo "ERROR: .env not found"; exit 1; }
set -a
. ./.env
set +a
docker compose up -d --wait
mkdir -p backups
stamp="$(date +%Y-%m-%d-%H%M%S)"
dir="backups/backup-$stamp"
mkdir "$dir"
docker compose exec -T db sh -c 'exec mysqldump --single-transaction --routines --triggers --events -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' | gzip -9 > "$dir/database.sql.gz"
tar -C app/wp-content -czf "$dir/uploads.tar.gz" uploads
test -s "$dir/database.sql.gz"
test -s "$dir/uploads.tar.gz"
gzip -t "$dir/database.sql.gz"
tar -tzf "$dir/uploads.tar.gz" >/dev/null
echo "Backup created: $dir"
