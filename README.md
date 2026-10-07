# WP Base

Versioned WordPress Docker project.

## Stack

- WordPress 7.1.2
- PHP 8.4 FPM Alpine
- MySQL 8.4
- Nginx 1.30.5 Alpine
- WP-CLI 2.12.0
- Astra 4.14.0
- Google Authenticator 0.56
- WPS Hide Login 1.9.19

## New installation

Create the local environment file and set real local DB credentials:

```bash
cp .env.example .env
chmod 600 .env
```

Pull the versioned application image:

```bash
docker pull wpbuild1base/wp-base:1.0.0
```

Start the stack and install WordPress:

```bash
docker compose up -d --wait
./scripts/install.sh
./scripts/verify.sh
```

## Existing restore

On a new machine:

1. Clone this repository.
2. Create `.env` from `.env.example`.
3. Set the destination DB credentials and site settings in `.env`.
4. Pull the versioned application image.
5. Start the stack.
6. Restore the backup.

```bash
docker pull wpbuild1base/wp-base:1.0.0
docker compose up -d --wait
./scripts/restore.sh backups/backup-YYYY-MM-DD-HHMMSS
./scripts/verify.sh
```

The database backup contains WordPress users and site settings. Uploads are restored separately.

## Daily operation

```bash
docker compose up -d
docker compose down
docker compose up -d --wait
./scripts/verify.sh
```

Normal `docker compose down` preserves named volumes. `docker compose down -v` removes the named database and WordPress application volumes and is destructive.

## Backup

```bash
./scripts/backup.sh
```

Creates:

```text
backups/backup-YYYY-MM-DD-HHMMSS/
├── database.sql.gz
└── uploads.tar.gz
```

Backups are intentionally ignored by Git.

## Release

```bash
./scripts/release.sh
```

The release script asks for patch, minor, major, or custom SemVer. It requires a clean Git tree, builds the versioned WordPress image, checks the image, pushes it to Docker Hub, updates the project version, creates a Git tag, and pushes the commit and tag.

Release does not destroy runtime volumes and does not restore a database. Deployment and restore are separate operations.

## WP-CLI

```bash
./scripts/wp.sh core version
./scripts/wp.sh plugin list
./scripts/wp.sh theme list
```

## Data model

The versioned WordPress image contains WordPress core, WP-CLI, Astra, Google Authenticator, WPS Hide Login, and PHP configuration.

MySQL data is persisted in the named `wp_base_db_data` volume. The WordPress application tree is initialized into the named `wp_base_wordpress_data` volume. Uploads are persisted separately in `app/wp-content/uploads` and included in backups.

Automatic WordPress core updates are disabled. Dependency changes should be made deliberately and released as a new image version.

## Local migration simulation

A migration test should use a clean clone, a fresh `.env`, fresh Docker volumes, the versioned image, and a backup:

```text
git clone
  ↓
.env
  ↓
docker pull
  ↓
docker compose up
  ↓
restore.sh
  ↓
verify.sh
  ↓
same site
```

This project is local/dev-first. Remote/live hardening, including token-based access, is intentionally a later step.
