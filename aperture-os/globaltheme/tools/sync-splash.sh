#!/usr/bin/env bash
# Copies the splash from the sibling splash repo into this Look-and-Feel package.
# Plasma sets ksplashrc to the Global Theme's own id when it is applied, so the
# Global Theme must ship the splash itself (the standalone splash repo stays the source).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$HERE/../splash/aperture-os.splash/contents/splash}"
[[ -d "$SRC" ]] || { echo "splash source not found: $SRC" >&2; exit 1; }
rm -rf "$HERE/aperture-os/contents/splash"
cp -r "$SRC" "$HERE/aperture-os/contents/splash"
echo "synced splash from $SRC"
