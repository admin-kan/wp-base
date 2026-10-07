# WP Base

Versioned WordPress Docker project.

## Stack

WordPress 7.1.2, PHP 8.4 FPM Alpine, MySQL 8.4, Nginx 1.30.5 Alpine, WP-CLI 2.12.0, Astra 4.14.0, Google Authenticator 0.56, WPS Hide Login 1.9.19.

## New installation

cp .env.example .env
docker build -f docker/wordpress/Dockerfile -t wpbuild1base/wp-base:1.0.0 .
docker compose up -d
./scripts/install.sh
./scripts/verify.sh

## Existing restore

cp .env.example .env
docker compose pull
docker compose up -d
./scripts/restore.sh backups/backup-YYYY-MM-DD-HHMM
./scripts/verify.sh

## Daily

docker compose up -d
docker compose down
./scripts/verify.sh

docker compose down preserves named volumes. docker compose down -v removes named volumes and deletes the database volume.

## Backup

./scripts/backup.sh

Creates backups/backup-YYYY-MM-DD-HHMM/database.sql.gz and uploads.tar.gz.

## Release

./scripts/release.sh

The script asks for patch, minor, major, or custom version.

## WP-CLI

./scripts/wp.sh core version
./scripts/wp.sh plugin list
./scripts/wp.sh theme list

## Data model

Application code and fixed dependency versions are in the versioned WordPress image. Database data is in the named MySQL volume. Uploads are persisted in app/wp-content/uploads and included in backups.
