#!/usr/bin/env bash
# Aperture OS - PhpStorm theme installer
#   ./install.sh               install / update the plugin jar
#   ./install.sh --uninstall   remove it again
# Only touches <plugins-dir>/aperture-os-theme.jar. Never edits PhpStorm
# config, never activates the theme, never stops a running PhpStorm.
# Override the target with PHPSTORM_PLUGINS_DIR=/path ./install.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR_NAME="aperture-os-theme.jar"
SRC="$HERE/dist/$JAR_NAME"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/JetBrains"

find_plugins_dir() {
    if [[ -n "${PHPSTORM_PLUGINS_DIR:-}" ]]; then
        echo "$PHPSTORM_PLUGINS_DIR"; return
    fi
    # Since 2020.1 plugins live directly in ~/.local/share/JetBrains/<Product><Version>/
    if [[ -d "$DATA/PhpStorm2026.2" ]]; then
        echo "$DATA/PhpStorm2026.2"; return
    fi
    local newest
    newest="$(find "$DATA" -maxdepth 1 -type d -name 'PhpStorm20*' 2>/dev/null | sort -V | tail -n1 || true)"
    if [[ -n "$newest" ]]; then
        echo "$newest"; return
    fi
    echo "$DATA/PhpStorm2026.2"
}

PLUGINS_DIR="$(find_plugins_dir)"
TARGET="$PLUGINS_DIR/$JAR_NAME"

case "${1:-}" in
    --uninstall|-u)
        if [[ -f "$TARGET" ]]; then
            rm -f -- "$TARGET"
            echo "Removed: $TARGET"
            echo "Restart PhpStorm. If 'Aperture OS' was active, PhpStorm falls back to the default theme."
        else
            echo "Not installed: $TARGET"
        fi
        ;;
    ""|--install)
        if [[ ! -f "$SRC" ]]; then
            echo "dist/$JAR_NAME missing - rebuilding ..."
            python3 "$HERE/tools/build.py"
        fi
        mkdir -p -- "$PLUGINS_DIR"
        install -m 0644 -- "$SRC" "$TARGET"
        echo "Installed: $TARGET"
        echo "Restart PhpStorm, then activate:"
        echo "  Settings > Appearance & Behavior > Appearance > Theme: Aperture OS"
        echo "  Settings > Editor > Color Scheme: Aperture OS"
        ;;
    -h|--help)
        sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        echo "Unknown option: $1 (allowed: --uninstall, --help)" >&2
        exit 2
        ;;
esac
