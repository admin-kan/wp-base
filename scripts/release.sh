#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CURRENT="$(grep '^WP_IMAGE=' .env.example | sed 's/.*://' | head -1)"
[ -n "$CURRENT" ] || CURRENT=1.0.0

echo "Current version: $CURRENT"
echo "1) patch"
echo "2) minor"
echo "3) major"
echo "4) custom"
echo "5) cancel"
read -r -p "Choose: " CHOICE

case "$CHOICE" in
  1) NEXT="$(printf '%s' "$CURRENT" | awk -F. '{printf "%d.%d.%d\n",$1,$2,$3+1}')" ;;
  2) NEXT="$(printf '%s' "$CURRENT" | awk -F. '{printf "%d.%d.0\n",$1,$2+1}')" ;;
  3) NEXT="$(printf '%s' "$CURRENT" | awk -F. '{printf "%d.0.0\n",$1+1}')" ;;
  4) read -r -p "Version: " NEXT ;;
  5) exit 0 ;;
  *) echo "ERROR: invalid choice"; exit 1 ;;
esac

echo "$NEXT" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
  echo "ERROR: invalid SemVer"
  exit 1
}

TAG="v$NEXT"
IMAGE="wpbuild1base/wp-base:$NEXT"

git diff --check
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: working tree/index must be clean before release."
  git status --short
  exit 1
fi

echo "Release: $TAG"
echo "Image:   $IMAGE"
read -r -p "Build and push this release? [y/N] " CONFIRM
[ "$CONFIRM" = y ] || [ "$CONFIRM" = Y ] || exit 0

docker build -f docker/wordpress/Dockerfile -t "$IMAGE" .
docker run --rm "$IMAGE" wp --allow-root --path=/usr/src/wordpress core version >/dev/null
docker push "$IMAGE"

sed -i "s#^WP_IMAGE=.*#WP_IMAGE=$IMAGE#" .env.example
sed -i "s#^WP_IMAGE=.*#WP_IMAGE=$IMAGE#" .env

git diff --check
git add .env.example scripts/install.sh scripts/backup.sh scripts/release.sh
git commit -m "release: $TAG"
git tag "$TAG"
git push origin HEAD
git push origin "$TAG"

echo "Release completed: $TAG"
