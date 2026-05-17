#!/usr/bin/env bash
set -euo pipefail

NIX_FILE="pkgs/motivewave/default.nix"

CURRENT_HASH=$(grep 'sha256 =' "$NIX_FILE" | head -1 | sed -E 's/.*sha256 = "([^"]+)".*/\1/')
echo "Current hash: $CURRENT_HASH"

DOWNLOAD_URL="https://www.motivewave.com/update/download.do?file_type=LINUX"
echo "Following redirect: $DOWNLOAD_URL"
NEW_URL=$(curl -Ls -o /dev/null -w '%{url_effective}' "$DOWNLOAD_URL")

if [ -z "$NEW_URL" ]; then
  echo "Error: could not resolve download URL"
  exit 1
fi
echo "Resolved URL: $NEW_URL"

NEW_HASH=$(nix-prefetch-url "$NEW_URL")
echo "New hash: $NEW_HASH"

if [ "$CURRENT_HASH" = "$NEW_HASH" ]; then
  echo "motivewave is already up to date."
  exit 0
fi

NEW_VERSION=$(echo "$NEW_URL" | sed -n 's/.*motivewave_\(.*\)_amd64.deb/\1/p')
if [ -z "$NEW_VERSION" ]; then
  echo "Error: could not parse version from URL: $NEW_URL"
  exit 1
fi
echo "New version: $NEW_VERSION"

sed -i "s|version = \".*\"|version = \"$NEW_VERSION\"|" "$NIX_FILE"
sed -i "s|sha256 = \".*\"|sha256 = \"$NEW_HASH\"|" "$NIX_FILE"

echo "Updated motivewave → $NEW_VERSION"
