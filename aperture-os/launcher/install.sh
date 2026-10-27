#!/usr/bin/env bash
# Aperture Launcher – install / upgrade / uninstall the Plasma 6 launcher plasmoid.
#   ./install.sh              install or upgrade into ~/.local/share/plasma/plasmoids
#   ./install.sh --activate   install + replace Kickoff in all panels (appletsrc is backed up)
#   ./install.sh --deactivate put Kickoff back (its old settings were kept)
#   ./install.sh --uninstall  deactivate, then remove only aperture-os.launcher
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

ID="aperture-os.launcher"
TYPE="Plasma/Applet"

command -v kpackagetool6 >/dev/null 2>&1 || { echo "Error: kpackagetool6 not found (package libplasma / plasma-framework)." >&2; exit 1; }

is_installed() {
    kpackagetool6 -t "$TYPE" --list 2>/dev/null | grep -qx "$ID"
}

usage() {
    sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
}

APPLETSRC="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os"

# swap_plugin FROM TO: replaces the plugin of panel applets (only applets,
# not containments) while plasmashell is stopped - a running shell would
# overwrite the file. The applet keeps its id, position and config groups.
swap_plugin() {
    local from="$1" to="$2"
    [[ -f "$APPLETSRC" ]] || { echo "no panel configuration found: $APPLETSRC" >&2; return 1; }
    if ! grep -qx "plugin=$from" "$APPLETSRC"; then
        echo "no $from in the panel – nothing to do"
        return 0
    fi
    mkdir -p "$STATE"
    local bak
    bak="$STATE/appletsrc-$(date +%Y%m%d-%H%M%S)-launcher"
    cp -a "$(readlink -f "$APPLETSRC")" "$bak"
    echo "backed up:    $bak"
    systemctl --user stop plasma-plasmashell.service
    python3 - "$APPLETSRC" "$from" "$to" <<'PY'
import re, sys
path, old, new = sys.argv[1:]
group = None
out = []
for line in open(path, encoding="utf-8"):
    m = re.match(r"^\[(.*)\]\s*$", line)
    if m:
        group = m.group(1)
    elif group and re.fullmatch(r"Containments\]\[\d+\]\[Applets\]\[\d+", group) \
            and line.rstrip("\n") == "plugin=" + old:
        line = "plugin=" + new + "\n"
    out.append(line)
open(path, "w", encoding="utf-8").writelines(out)
PY
    systemctl --user start plasma-plasmashell.service
    echo "Panel:        $from → $to"
}

case "${1:-}" in
    -h|--help)
        usage
        ;;
    --activate)
        "$0"
        swap_plugin org.kde.plasma.kickoff "$ID"
        ;;
    --deactivate)
        swap_plugin "$ID" org.kde.plasma.kickoff
        ;;
    --uninstall)
        swap_plugin "$ID" org.kde.plasma.kickoff
        if is_installed; then
            kpackagetool6 -t "$TYPE" -r "$ID" >/dev/null
            echo "removed:      $ID"
        else
            echo "not present: $ID"
        fi
        ;;
    "")
        if is_installed; then
            kpackagetool6 -t "$TYPE" -u "$ID" >/dev/null
            echo "updated:      $ID"
        else
            kpackagetool6 -t "$TYPE" -i "$ID" >/dev/null
            echo "installed:    $ID"
        fi
        echo
        echo "Activate: ./install.sh --activate (replaces Kickoff in all panels, Meta then opens the launcher)"
        echo "or right-click the Kickoff button → \"Show Alternatives …\" → \"Aperture Launcher\"."
        echo "Note: an already placed launcher only loads updates after a new Plasma session."
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
esac
