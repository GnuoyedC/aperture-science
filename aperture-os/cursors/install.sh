#!/usr/bin/env bash
# Aperture-cursors – Installer
#   ./install.sh               installs to ~/.icons/Aperture-cursors (does NOT activate)
#   ./install.sh --activate    installs and sets Aperture-cursors as the active pointer
#   ./install.sh --uninstall   only removes ~/.icons/Aperture-cursors
set -euo pipefail

THEME="Aperture-cursors"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${THEME}"
# KDE's pointer settings (Plasma 6.6) only find cursors in ~/.icons and /usr/share/icons,
# not in ~/.local/share/icons – hence ~/.icons.
DEST_BASE="$HOME/.icons"
LEGACY="${XDG_DATA_HOME:-$HOME/.local/share}/icons/Aperture-cursors"   # location of older versions
DEST="${DEST_BASE}/${THEME}"

mode="install"
activate=0
for arg in "$@"; do
    case "$arg" in
        --uninstall) mode="uninstall" ;;
        --activate)  activate=1 ;;
        -h|--help)   sed -n '2,5p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

if [[ "$mode" == "uninstall" ]]; then
    rm -rf -- "$LEGACY"
    if [[ -e "$DEST" || -L "$DEST" ]]; then
        rm -rf -- "$DEST"
        echo "Removed: $DEST"
    else
        echo "Not installed: $DEST"
    fi
    if command -v kreadconfig6 >/dev/null 2>&1; then
        current="$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme 2>/dev/null || true)"
        if [[ "$current" == "$THEME" ]]; then
            echo "Note: $THEME was active. Back to Breeze: plasma-apply-cursortheme breeze_cursors"
        fi
    fi
    exit 0
fi

if [[ ! -f "$SRC/index.theme" ]]; then
    echo "Error: $SRC/index.theme missing – run 'python3 tools/build.py' first." >&2
    exit 1
fi

mkdir -p "$DEST_BASE"
rm -rf -- "$DEST"
rm -rf -- "$LEGACY"
cp -a -- "$SRC" "$DEST"   # -a preserves the alias symlinks
echo "Installed: $DEST"

if (( activate )); then
    if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
        plasma-apply-cursortheme "$THEME"
    else
        echo "plasma-apply-cursortheme not found – please activate it in System Settings." >&2
    fi
else
    echo "Not activated. Activate: System Settings → Colors & Themes → Pointer"
    echo "           or: plasma-apply-cursortheme $THEME"
fi
