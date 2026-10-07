#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "ERROR: .env not found"; exit 1; }
set -a
. ./.env
set +a

echo "Checking Docker Compose..."
docker compose config >/dev/null

echo "Checking services..."
docker compose ps --status running >/dev/null

echo "Checking database..."
docker compose exec -T db sh -lc 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqladmin ping -h 127.0.0.1 -u root --silent' >/dev/null

echo "Checking WordPress container..."
docker compose exec -T wordpress php-fpm -t >/dev/null 2>&1

echo "Checking wp-config.php..."
docker compose exec -T wordpress test -s /var/www/html/wp-config.php

echo "Checking PHP..."
docker compose exec -T wordpress php -v >/dev/null

echo "Checking WP-CLI..."
docker compose exec -T wordpress wp --allow-root cli version >/dev/null

echo "Checking WordPress core..."
core_version="$(docker compose exec -T wordpress wp --allow-root core version | tr -d '
')"
[ "$core_version" = "7.1.2" ] || { echo "ERROR: expected WordPress 7.1.2, got $core_version"; exit 1; }

docker compose exec -T wordpress wp --allow-root core is-installed >/dev/null

echo "Checking Astra..."
astra_version="$(docker compose exec -T wordpress wp --allow-root theme get astra --field=version | tr -d '
')"
[ "$astra_version" = "4.14.0" ] || { echo "ERROR: expected Astra 4.14.0, got $astra_version"; exit 1; }

echo "Checking Google Authenticator..."
ga_version="$(docker compose exec -T wordpress wp --allow-root plugin get google-authenticator --field=version | tr -d '
')"
[ "$ga_version" = "0.56" ] || { echo "ERROR: expected Google Authenticator 0.56, got $ga_version"; exit 1; }

echo "Checking WPS Hide Login..."
wps_version="$(docker compose exec -T wordpress wp --allow-root plugin get wps-hide-login --field=version | tr -d '
')"
[ "$wps_version" = "1.9.19" ] || { echo "ERROR: expected WPS Hide Login 1.9.19, got $wps_version"; exit 1; }

echo "Checking uploads..."
test -d app/wp-content/uploads

echo "Checking HTTP..."
curl -fsS -L --max-redirs 5 -o /tmp/wp-verify.html -w '%{http_code}' "$WP_SITE_URL/" | grep -qx '200'

echo "Checking site title..."
grep -q '<title>' /tmp/wp-verify.html

echo "VERIFY: PASSED"
