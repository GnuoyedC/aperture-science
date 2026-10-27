#!/usr/bin/env bash
# Aperture OS widgets – install / upgrade / uninstall the Plasma 6 plasmoids.
#   ./install.sh              install or upgrade into ~/.local/share/plasma/plasmoids
#   ./install.sh --uninstall  remove only the Aperture OS widgets
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

PACKAGES=(aperture-os.testchamber aperture-os.sysmonitor aperture-os.notice)
TYPE="Plasma/Applet"

command -v kpackagetool6 >/dev/null 2>&1 || { echo "Error: kpackagetool6 not found (package plasma-framework / libplasma)." >&2; exit 1; }

is_installed() {
    kpackagetool6 -t "$TYPE" --list 2>/dev/null | grep -qx "$1"
}

usage() {
    sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
    -h|--help)
        usage
        ;;
    --uninstall)
        for id in "${PACKAGES[@]}"; do
            if is_installed "$id"; then
                kpackagetool6 -t "$TYPE" -r "$id" >/dev/null
                echo "removed:      $id"
            else
                echo "not present: $id"
            fi
        done
        ;;
    "")
        for id in "${PACKAGES[@]}"; do
            if is_installed "$id"; then
                kpackagetool6 -t "$TYPE" -u "$id" >/dev/null
                echo "updated:      $id"
            else
                kpackagetool6 -t "$TYPE" -i "$id" >/dev/null
                echo "installed:    $id"
            fi
        done
        echo
        echo "Add: right-click the desktop → Add Widgets → search for \"Aperture\"."
        echo "Note: widgets that are already placed only load updates after a new Plasma session."
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
esac
