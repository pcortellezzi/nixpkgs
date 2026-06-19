#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "=== Checking for npm package updates ==="
npx -y npm-check-updates -u

echo "=== Regenerating lockfile (full install for complete resolution) ==="
npm install

echo "=== Setting fake hash to discover real one ==="
sed -i 's|npmDepsHash = "sha256-.*"|npmDepsHash = lib.fakeHash|' default.nix

echo "=== Building to discover npmDepsHash ==="
HASH=$(nix build 2>&1 '.#opencode-plugins' | grep -oP 'got:\s*\K(sha256-.*)' || true)

if [ -n "$HASH" ]; then
  sed -i "s|npmDepsHash = lib\\.fakeHash|npmDepsHash = \"$HASH\"|" default.nix
  echo "Updated npmDepsHash to: $HASH"
else
  echo "ERROR: could not compute npmDepsHash"
  exit 1
fi

echo "=== Done ==="
