#!/usr/bin/env bash
# Builds a ZIP/tar.gz per component for store.kde.org (output: dist/).
# Each package can be installed directly via "kpackagetool6 -i" or System Settings → "Get New …".
#   tools/package-store.sh
# New or renamed packages: also update the release asset links in .gitlab-ci.yml.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/dist"
rm -rf "$OUT"; mkdir -p "$OUT"

pack() {   # pack <source folder (contains the package directory)> <package directory> <target name>
    (cd "$ROOT/$1" && zip -qr "$OUT/$3.zip" "$2" -x '*.pyc' '*/__pycache__/*')
    echo "dist/$3.zip"
}
pack globaltheme aperture-os aperture-os-globaltheme
pack plasma-style aperture-os aperture-os-plasma-style
pack aurorae aperture-os aperture-os-window-decoration
pack splash aperture-os.splash aperture-os-splash
pack lockscreen aperture-os.shell aperture-os-lockscreen
pack launcher aperture-os.launcher aperture-os-launcher
pack cursors Aperture-cursors aperture-os-cursors
for w in widgets/aperture-os.*; do pack widgets "$(basename "$w")" "$(basename "$w")-widget"; done
pack wallpaper ApertureTestChamber aperture-os-wallpaper
(cd "$ROOT" && cp colors/ApertureOS.colors "$OUT/" && echo dist/ApertureOS.colors)
(cd "$ROOT" && tar czf "$OUT/aperture-protocol-sddm.tar.gz" --exclude=sddm/tools --exclude=sddm/install.sh --transform 's,^sddm,aperture-protocol,' sddm && echo dist/aperture-protocol-sddm.tar.gz)
