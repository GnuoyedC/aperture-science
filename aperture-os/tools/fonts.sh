#!/usr/bin/env bash
# Aperture OS fonts: Inter (UI) + JetBrains Mono (technical labels / editor)
#                    + Barlow Semi Condensed (display titles: TEST CHAMBER 01 ...).
# Both are SIL Open Font License. Installed per user into ~/.local/share/fonts/aperture-os.
#
#   tools/fonts.sh              download + install the fonts only
#   tools/fonts.sh --apply      also set the KDE fonts (previous values are backed up)
#   tools/fonts.sh --restore    restore the KDE fonts from the backup
#   tools/fonts.sh --uninstall  restore + remove the font files
#
# KDE font roles set by --apply (sizes from design/tokens.json font.uiSize):
#   General / Menu / Toolbar / Window title : Inter 10
#   Small                                    : Inter 8
#   Fixed width                              : JetBrains Mono 10
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/aperture-os"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os"
BACKUP="$STATE/fonts.prev"
INTER_VER="4.1"
JBM_VER="2.304"

download() {
    local tmp; tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN
    mkdir -p "$DEST"
    if ! fc-list | grep "$DEST/Inter" >/dev/null; then
        echo "downloading Inter $INTER_VER"
        curl -sfL --retry 3 -o "$tmp/inter.zip" \
            "https://github.com/rsms/inter/releases/download/v$INTER_VER/Inter-$INTER_VER.zip"
        unzip -q -o "$tmp/inter.zip" -d "$tmp/inter"
        # static TTFs give the most predictable hinting in Qt
        find "$tmp/inter" -path '*extras/ttf/*' -name 'Inter-*.ttf' -exec cp {} "$DEST/" \;
        [[ -n "$(ls "$DEST"/Inter-*.ttf 2>/dev/null)" ]] || find "$tmp/inter" -name 'Inter*.ttf' -exec cp {} "$DEST/" \;
    fi
    if ! fc-list | grep "$DEST/JetBrainsMono" >/dev/null; then
        echo "downloading JetBrains Mono $JBM_VER"
        curl -sfL --retry 3 -o "$tmp/jbm.zip" \
            "https://github.com/JetBrains/JetBrainsMono/releases/download/v$JBM_VER/JetBrainsMono-$JBM_VER.zip"
        unzip -q -o "$tmp/jbm.zip" -d "$tmp/jbm"
        find "$tmp/jbm" -path '*fonts/ttf/*' -name 'JetBrainsMono-*.ttf' -exec cp {} "$DEST/" \;
    fi
    if ! fc-list | grep "$DEST/BarlowSemiCondensed" >/dev/null; then
        echo "downloading Barlow Semi Condensed"
        for w in Regular Medium SemiBold; do
            curl -sfL --retry 3 -o "$DEST/BarlowSemiCondensed-$w.ttf" \
                "https://github.com/google/fonts/raw/main/ofl/barlowsemicondensed/BarlowSemiCondensed-$w.ttf"
        done
    fi
    fc-cache -f "$DEST" >/dev/null
    echo "fonts installed in $DEST ($(ls "$DEST" | wc -l) files)"
}

KEYS=(font menuFont toolBarFont smallestReadableFont fixed)
backup() {
    mkdir -p "$STATE"
    [[ -e "$BACKUP" ]] && return
    {
        for k in "${KEYS[@]}"; do echo "General:$k=$(kreadconfig6 --file kdeglobals --group General --key "$k")"; done
        echo "WM:activeFont=$(kreadconfig6 --file kdeglobals --group WM --key activeFont)"
    } > "$BACKUP"
}

apply() {
    fc-list : family | grep -x "Inter" >/dev/null || { echo "Inter not installed" >&2; exit 1; }
    backup
    local ui="Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    local small="Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    local mono="JetBrains Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    local title="Inter,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Medium"
    kwriteconfig6 --file kdeglobals --group General --key font "$ui"
    kwriteconfig6 --file kdeglobals --group General --key menuFont "$ui"
    kwriteconfig6 --file kdeglobals --group General --key toolBarFont "$ui"
    kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$small"
    kwriteconfig6 --file kdeglobals --group General --key fixed "$mono"
    kwriteconfig6 --file kdeglobals --group WM --key activeFont "$title"
    echo "KDE fonts set (new windows use them immediately, log out/in for everything)."
}

restore() {
    [[ -e "$BACKUP" ]] || { echo "no font backup found"; return; }
    while IFS= read -r line; do
        local gk=${line%%=*} val=${line#*=}
        local g=${gk%%:*} k=${gk#*:}
        if [[ -z "$val" ]]; then
            kwriteconfig6 --file kdeglobals --group "$g" --key "$k" --delete
        else
            kwriteconfig6 --file kdeglobals --group "$g" --key "$k" "$val"
        fi
    done < "$BACKUP"
    rm "$BACKUP"
    echo "KDE fonts restored."
}

case "${1:-}" in
    "") download ;;
    --apply) download; apply ;;
    --restore) restore ;;
    --uninstall) restore; rm -rf "$DEST"; fc-cache -f >/dev/null; echo "fonts removed" ;;
    *) sed -n '2,13p' "$0"; exit 2 ;;
esac
