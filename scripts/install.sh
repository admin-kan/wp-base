#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "ERROR: .env not found"; exit 1; }
docker info >/dev/null
docker compose config >/dev/null

set -a
. ./.env
set +a

if [ -n "${WP_ADMIN_USER:-}" ] && [ -n "${WP_ADMIN_EMAIL:-}" ] && { [ -n "${WP_ADMIN_PASSWORD:-}" ] || [ -n "${WP_ADMIN_PASSWORD_FILE:-}" ]; }; then
  ADMIN_USER="$WP_ADMIN_USER"
  ADMIN_EMAIL="$WP_ADMIN_EMAIL"
  if [ -n "${WP_ADMIN_PASSWORD_FILE:-}" ]; then
    [ -f "$WP_ADMIN_PASSWORD_FILE" ] || { echo "ERROR: WP_ADMIN_PASSWORD_FILE not found"; exit 1; }
    IFS= read -r ADMIN_PASSWORD < "$WP_ADMIN_PASSWORD_FILE"
  else
    ADMIN_PASSWORD="$WP_ADMIN_PASSWORD"
  fi
else
  read -r -p "WordPress admin username: " ADMIN_USER
  read -r -s -p "WordPress admin password: " ADMIN_PASSWORD
  echo
  read -r -p "WordPress admin email: " ADMIN_EMAIL
fi

[ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASSWORD" ] && [ -n "$ADMIN_EMAIL" ] || {
  echo "ERROR: admin values cannot be empty"
  exit 1
}

docker compose up -d --wait

for i in $(seq 1 60); do
  if docker compose exec -T wordpress php -r '$m=new mysqli(getenv("WORDPRESS_DB_HOST"),getenv("WORDPRESS_DB_USER"),getenv("WORDPRESS_DB_PASSWORD"),getenv("WORDPRESS_DB_NAME")); if ($m->connect_errno) { exit(1); }' >/dev/null 2>&1; then
    break
  fi
  [ "$i" -eq 60 ] && { echo "ERROR: database not ready"; exit 1; }
  sleep 2
done

fresh_install=0
if docker compose exec -T wordpress wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "WordPress already installed; install.sh will not reinstall it."
else
  docker compose exec -T wordpress wp core install     --allow-root     --url="$WP_SITE_URL"     --title="$WP_SITE_TITLE"     --admin_user="$ADMIN_USER"     --admin_password="$ADMIN_PASSWORD"     --admin_email="$ADMIN_EMAIL"     --skip-email
  fresh_install=1
fi

docker compose exec -T wordpress test -s /var/www/html/wp-config.php || { echo "ERROR: wp-config.php was not created"; exit 1; }

docker compose exec -T wordpress wp theme activate astra --allow-root
docker compose exec -T wordpress wp plugin activate google-authenticator wps-hide-login --allow-root

if [ "$fresh_install" -eq 1 ]; then
  echo "Checking default WordPress pages from fresh installation..."

  sample_page="$(docker compose exec -T wordpress wp post list --post_type=page --post_status=publish --title='Sample Page' --field=ID --allow-root | tr -d '\r')"
  privacy_page="$(docker compose exec -T wordpress wp option get wp_page_for_privacy_policy --allow-root | tr -d '\r')"

  [ -n "$sample_page" ] || {
    echo "ERROR: default Sample Page is missing after fresh installation"
    exit 1
  }

  [ -n "$privacy_page" ] && [ "$privacy_page" != "0" ] || {
    echo "ERROR: Privacy Policy page ID is missing after fresh installation"
    exit 1
  }

  privacy_status="$(docker compose exec -T wordpress wp post get "$privacy_page" --field=post_status --allow-root | tr -d '\r')"
  [ "$privacy_status" = "draft" ] || {
    echo "ERROR: Privacy Policy page has unexpected status: $privacy_status"
    exit 1
  }

  echo "Pages OK: Sample Page ID=$sample_page; Privacy Policy ID=$privacy_page"
else
  echo "Existing site detected; default page creation check skipped."
fi

./scripts/verify.sh
