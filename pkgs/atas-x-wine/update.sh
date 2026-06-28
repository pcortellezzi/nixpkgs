#!/usr/bin/env bash
set -euo pipefail

NIX_FILE="pkgs/atas-x-wine/default.nix"

CURRENT_REV=$(grep 'rev =' "$NIX_FILE" | head -1 | cut -d'"' -f2)
echo "Current rev: $CURRENT_REV"

# Use REF from env if set (repository_dispatch), else query GitHub API
if [ -n "${REF:-}" ]; then
  LATEST_REV="$REF"
else
  API_URL="https://api.github.com/repos/pcortellezzi/atas-x-wine/commits/main"
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    LATEST_REV=$(curl -sSL -H "Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | jq -r '.sha')
  else
    LATEST_REV=$(curl -sSL "$API_URL" | jq -r '.sha')
  fi
fi

if [ -z "$LATEST_REV" ] || [ "$LATEST_REV" = "null" ]; then
  echo "Error: could not fetch latest commit"
  exit 1
fi

echo "Latest rev: $LATEST_REV"

if [ "$LATEST_REV" = "$CURRENT_REV" ]; then
  echo "atas-x-wine is already up to date."
  exit 0
fi

echo "Fetching new hash for rev $LATEST_REV ..."
NEW_HASH=$(nix flake prefetch --json "github:pcortellezzi/atas-x-wine/$LATEST_REV" 2>/dev/null | jq -r '.hash')

if [ -z "$NEW_HASH" ] || [ "$NEW_HASH" = "null" ]; then
  echo "Error: could not compute new hash"
  exit 1
fi

echo "New hash: $NEW_HASH"

sed -i "s|rev = \"$CURRENT_REV\"|rev = \"$LATEST_REV\"|" "$NIX_FILE"
sed -i "s|sha256 = \".*\"|sha256 = \"$NEW_HASH\"|" "$NIX_FILE"

echo "Updated atas-x-wine $CURRENT_REV → $LATEST_REV"
