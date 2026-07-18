#!/usr/bin/env bash
set -euo pipefail

NIX_FILE="pkgs/codex/default.nix"

CURRENT_VERSION=$(grep 'version =' "$NIX_FILE" | head -1 | cut -d'"' -f2)
echo "Current version: $CURRENT_VERSION"

LATEST_DATA=$(curl -sSL https://api.github.com/repos/openai/codex/releases/latest)
LATEST_TAG=$(echo "$LATEST_DATA" | jq -r .tag_name)

if [ "$LATEST_TAG" = "null" ] || [ -z "$LATEST_TAG" ]; then
  echo "Error: could not fetch latest release from GitHub API"
  exit 1
fi

LATEST_VERSION=$(echo "$LATEST_TAG" | sed 's/^rust-v//')
echo "Latest version: $LATEST_VERSION"

if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
  echo "codex is already up to date."
  exit 0
fi

MAIN_URL="https://github.com/openai/codex/releases/download/rust-v${LATEST_VERSION}/codex-package-x86_64-unknown-linux-musl.tar.gz"
MODE_HOST_URL="https://github.com/openai/codex/releases/download/rust-v${LATEST_VERSION}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz"

echo "Fetching main package hash..."
MAIN_HASH=$(nix-prefetch-url "$MAIN_URL")
echo "Main hash: $MAIN_HASH"

echo "Fetching code-mode-host hash..."
MODE_HOST_HASH=$(nix-prefetch-url "$MODE_HOST_URL")
echo "Code-mode-host hash: $MODE_HOST_HASH"

# Update version
sed -i "s|version = \"$CURRENT_VERSION\"|version = \"$LATEST_VERSION\"|" "$NIX_FILE"

# Update first sha256 (main src)
MAIN_LINE=$(grep -n 'sha256' "$NIX_FILE" | head -1 | cut -d: -f1)
sed -i "${MAIN_LINE}s|sha256 = \"[^\"]*\"|sha256 = \"$MAIN_HASH\"|" "$NIX_FILE"

# Update second sha256 (codeModeHostSrc)
MODE_LINE=$(grep -n 'sha256' "$NIX_FILE" | tail -1 | cut -d: -f1)
sed -i "${MODE_LINE}s|sha256 = \"[^\"]*\"|sha256 = \"$MODE_HOST_HASH\"|" "$NIX_FILE"

echo "Updated codex $CURRENT_VERSION → $LATEST_VERSION"
