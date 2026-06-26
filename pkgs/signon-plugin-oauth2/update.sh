#!/usr/bin/env bash
set -euo pipefail

NIX_FILE="pkgs/signon-plugin-oauth2/default.nix"

CURRENT_REV=$(grep 'rev =' "$NIX_FILE" | head -1 | cut -d'"' -f2)
echo "Current rev: $CURRENT_REV"

LATEST_REV=$(curl -sSL \
  "https://gitlab.com/api/v4/projects/nicolasfella%2Fsignon-plugin-oauth2/repository/branches/qt6" \
  | jq -r '.commit.id')

if [ "$LATEST_REV" = "null" ] || [ -z "$LATEST_REV" ]; then
  echo "Error: could not fetch latest commit from GitLab API"
  exit 1
fi

echo "Latest rev:   $LATEST_REV"

if [ "$LATEST_REV" = "$CURRENT_REV" ]; then
  echo "signon-plugin-oauth2 is already up to date."
  exit 0
fi

sed -i "s|rev = \"$CURRENT_REV\"|rev = \"$LATEST_REV\"|" "$NIX_FILE"

# Clear hash so Nix recomputes it
sed -i 's|hash = "[^"]*"|hash = ""|' "$NIX_FILE"

# Build to get the correct hash
BUILD_OUTPUT=$(nix build .#signon-plugin-oauth2 2>&1 || true)

NEW_HASH=$(echo "$BUILD_OUTPUT" | grep "got:" | head -1 | sed 's/.*: *//')

if [ -z "$NEW_HASH" ]; then
  echo "Error: could not extract hash from build output"
  echo "$BUILD_OUTPUT"
  exit 1
fi

sed -i 's|hash = ""|hash = "'"$NEW_HASH"'"|' "$NIX_FILE"

echo "Updated signon-plugin-oauth2 rev $CURRENT_REV → $LATEST_REV"
