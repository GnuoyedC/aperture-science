#!/usr/bin/env bash
# Installs the Aperture Protocol SDDM theme system-wide and activates it.
#
#   sudo ./install.sh              install + activate
#   sudo ./install.sh --no-activate  install only (select it in System Settings)
#   sudo ./install.sh --uninstall    remove theme and activation file
set -euo pipefail

THEME_ID="aperture-protocol"
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/${THEME_ID}"
CONF_FILE="/etc/sddm.conf.d/90-${THEME_ID}.conf"
ACTIVATE=1

for arg in "$@"; do
    case "$arg" in
        --no-activate) ACTIVATE=0 ;;
        --uninstall)
            [[ ${EUID} -eq 0 ]] || { echo "Run with sudo."; exit 1; }
            rm -rf -- "$THEME_DIR"
            rm -f -- "$CONF_FILE"
            echo "Removed ${THEME_DIR} and ${CONF_FILE}."
            exit 0 ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

if [[ ${EUID} -ne 0 ]]; then
    echo "Run this installer with sudo."
    exit 1
fi

if ! command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    echo "Warning: sddm-greeter-qt6 not found – this theme requires SDDM built against Qt 6."
fi
for module in QtQuick/Shapes QtQuick/Controls QtMultimedia; do
    if ! find /usr/lib*/ -path "*qt6/qml/${module}" -maxdepth 6 -type d 2>/dev/null | grep -q .; then
        echo "Note: Qt 6 QML module ${module//\//.} not found (sounds need QtMultimedia; Shapes/Controls are required)."
    fi
done

# Fresh copy: only runtime files, no dev tools.
rm -rf -- "$THEME_DIR"
install -d -m 0755 "$THEME_DIR"
cp -r "$SOURCE_DIR"/{Main.qml,metadata.desktop,theme.conf,components,assets,sounds} "$THEME_DIR"/
[[ -f "$SOURCE_DIR/theme.conf.user" ]] && cp "$SOURCE_DIR/theme.conf.user" "$THEME_DIR"/
chown -R root:root "$THEME_DIR"
find "$THEME_DIR" -type d -exec chmod 0755 {} +
find "$THEME_DIR" -type f -exec chmod 0644 {} +

if [[ $ACTIVATE -eq 1 ]]; then
    install -d -m 0755 "$(dirname "$CONF_FILE")"
    printf '%s\n' '[Theme]' "Current=${THEME_ID}" > "$CONF_FILE"
    chmod 0644 "$CONF_FILE"
fi

cat <<MSG

Aperture Protocol installed to ${THEME_DIR}.

Test without logging out:
  sddm-greeter-qt6 --test-mode --theme ${THEME_DIR}

$( [[ $ACTIVATE -eq 1 ]] && echo "Activated via ${CONF_FILE}. It is used on the next SDDM start." \
                          || echo "Select it in System Settings → Colours & Themes → Login Screen (SDDM)." )
MSG
