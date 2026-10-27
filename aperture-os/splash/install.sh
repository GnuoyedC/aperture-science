#!/usr/bin/env bash
# Aperture OS – Splash Screen "aperture-os.splash"
#   ./install.sh               install
#   ./install.sh --activate    install and set as splash screen
#   ./install.sh --preview     show the splash in test mode (approx. 8 s)
#   ./install.sh --uninstall   remove (if active: back to Breeze)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/look-and-feel/aperture-os.splash"
case "${1:-}" in
    ""|--activate)
        rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
        cp -r "$HERE/aperture-os.splash" "$DEST"
        echo "Splash installed: $DEST"
        if [[ "${1:-}" == --activate ]]; then
            kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
            kwriteconfig6 --file ksplashrc --group KSplash --key Theme aperture-os.splash
            echo "activated."
        fi
        ;;
    --preview) ksplashqml --test --nofork aperture-os.splash ;;
    --uninstall)
        if [[ "$(kreadconfig6 --file ksplashrc --group KSplash --key Theme)" == aperture-os.splash ]]; then
            kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop
        fi
        rm -rf "$DEST"
        echo "Splash removed."
        ;;
    *) sed -n '2,6p' "$0"; exit 2 ;;
esac
