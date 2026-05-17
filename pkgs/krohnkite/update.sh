#!/usr/bin/env bash
set -euo pipefail

NIX_FILE="pkgs/krohnkite/default.nix"

CURRENT_VERSION=$(grep 'version =' "$NIX_FILE" | head -1 | cut -d'"' -f2)
echo "Current version: $CURRENT_VERSION"

LATEST_TAG=$(curl -sSL https://codeberg.org/api/v1/repos/anametologin/Krohnkite/releases/latest | jq -r .tag_name)

if [ "$LATEST_TAG" = "null" ] || [ -z "$LATEST_TAG" ]; then
  echo "Error: could not fetch latest release from Codeberg API"
  exit 1
fi

echo "Latest version:  $LATEST_TAG"

if [ "$LATEST_TAG" = "$CURRENT_VERSION" ]; then
  echo "krohnkite is already up to date."
  exit 0
fi

URL="https://codeberg.org/anametologin/Krohnkite/releases/download/${LATEST_TAG}/krohnkite.kwinscript"
echo "Fetching $URL ..."
NEW_HASH=$(nix-prefetch-url "$URL")
echo "New hash: $NEW_HASH"

sed -i "s|version = \"$CURRENT_VERSION\"|version = \"$LATEST_TAG\"|" "$NIX_FILE"
sed -i "s|sha256 = \".*\"|sha256 = \"$NEW_HASH\"|" "$NIX_FILE"

echo "Updated krohnkite $CURRENT_VERSION → $LATEST_TAG"
