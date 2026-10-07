#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -a
. ./.env
set +a
fail=0
check() { if "$@"; then printf 'OK   %s\n' "$*"; else printf 'FAIL %s\n' "$*"; fail=1; fi; }
check docker compose config >/dev/null
check docker compose ps --status running >/dev/null
check docker compose exec -T db mysqladmin ping -h 127.0.0.1 -u root -p"$DB_ROOT_PASSWORD" --silent >/dev/null
check docker compose exec -T wordpress php -v >/dev/null
check docker compose exec -T wordpress wp core version --allow-root >/dev/null
check docker compose exec -T wordpress wp cli version --allow-root >/dev/null
check docker compose exec -T wordpress php -r '$m=new mysqli(getenv("WORDPRESS_DB_HOST"),getenv("WORDPRESS_DB_USER"),getenv("WORDPRESS_DB_PASSWORD"),getenv("WORDPRESS_DB_NAME")); if ($m->connect_errno) { exit(1); }' >/dev/null
core_version="$(docker compose exec -T wordpress wp core version --allow-root | tr -d '\r')"
[ "$core_version" = "7.1.2" ] || { echo "FAIL core version: $core_version"; fail=1; }
astra_version="$(docker compose exec -T wordpress wp theme get astra --field=version --allow-root | tr -d '\r')"
[ "$astra_version" = "4.14.0" ] || { echo "FAIL Astra version: $astra_version"; fail=1; }
ga_version="$(docker compose exec -T wordpress wp plugin get google-authenticator --field=version --allow-root | tr -d '\r')"
[ "$ga_version" = "0.56" ] || { echo "FAIL Google Authenticator version: $ga_version"; fail=1; }
wps_version="$(docker compose exec -T wordpress wp plugin get wps-hide-login --field=version --allow-root | tr -d '\r')"
[ "$wps_version" = "1.9.19" ] || { echo "FAIL WPS Hide Login version: $wps_version"; fail=1; }
check test -d app/wp-content/uploads
check curl -fsS "$WP_SITE_URL/healthz" >/dev/null
check curl -fsS "$WP_SITE_URL/" >/dev/null
login_url="$(docker compose exec -T wordpress wp eval 'echo wp_login_url();' --allow-root | tr -d '\r')"
check curl -fsS "$WP_SITE_URL/" >/dev/null
check curl -fsS -L "$login_url" >/dev/null
if [ "$fail" -ne 0 ]; then echo "VERIFY: FAILED"; exit 1; fi
echo "VERIFY: PASSED"
