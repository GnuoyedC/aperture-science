#!/usr/bin/env bash
# fetch_sounds.sh - (re)builds the freedesktop sound theme aperture-os/stereo/*.oga
# from original Portal 2 SFX.
#
# !! The resulting files are Valve Corporation game material (Portal 2, (c) Valve).
# !! PRIVATE, PERSONAL USE ONLY. The repo is private - do NOT publish it.
#
# Source: github.com/sourcesounds/portal2 (raw dump of Portal 2's sound/ tree),
# pinned to the same commit as aperture-sddm/tools/fetch_portal_sounds.sh, so the
# result is reproducible. Only SFX, no voice lines (the turret voice lines live in
# session/ and are played by systemd, not by this theme).
#
# Processing per event: optional start offset, leading silence trimmed, cut to
# <len> s with a short fade-in (anti-click) and fade-out, peak-normalised to
# <peak> dBFS, encoded as Ogg Vorbis 48 kHz stereo (like the Ocean theme).
# Frequent events (clicks, volume, chat) are <300 ms and quiet (-20..-22 dBFS).
#
# Output is bit-exact (fixed Ogg serials, no metadata), so re-runs give identical files.
# Requires: bash, curl, ffmpeg. Usage: tools/fetch_sounds.sh [--keep-raw]
set -euo pipefail
export LC_ALL=C   # decimal points for awk/printf, regardless of the desktop locale

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/aperture-os/stereo"
RAW="$(mktemp -d)"
if [[ "${1:-}" == "--keep-raw" ]]; then echo "raw files kept in $RAW"; else trap 'rm -rf "$RAW"' EXIT; fi

COMMIT=36edc8b85c4b5718289f56d8c3652a6dc0e58a1b
BASE="https://raw.githubusercontent.com/sourcesounds/portal2/$COMMIT/sound"

command -v ffmpeg >/dev/null || { echo "ffmpeg missing" >&2; exit 1; }
command -v curl   >/dev/null || { echo "curl missing" >&2; exit 1; }
mkdir -p "$OUT"

fetch() { # fetch <repo path> -> prints local path
    local dst
    dst="$RAW/$(echo "$1" | tr / _)"
    [[ -s "$dst" ]] || curl -sfL --retry 3 -m 120 -o "$dst" "$BASE/$1"
    echo "$dst"
}

peak_db() { # max_volume of a file in dBFS
    ffmpeg -hide_banner -nostats -i "$1" -af volumedetect -f null - 2>&1 \
        | sed -n 's/.*max_volume: \(-\?[0-9.]*\) dB.*/\1/p'
}

# make <event> <repo path> <start offset s> <length s> <fade-out s> <peak dBFS>
make() {
    local ev=$1 src; src=$(fetch "$2")
    local ss=$3 len=$4 fade=$5 peak=$6
    local tmp="$RAW/$ev.tmp.wav" gain fst
    fst=$(awk -v l="$len" -v f="$fade" 'BEGIN{print (l-f<0)?0:l-f}')
    ffmpeg -hide_banner -loglevel error -y -ss "$ss" -i "$src" -af \
"aformat=sample_fmts=flt:channel_layouts=stereo,\
silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.005,\
atrim=0:${len},asetpts=N/SR/TB,\
afade=t=in:d=0.004,afade=t=out:st=${fst}:d=${fade}" \
        -ar 48000 -c:a pcm_f32le "$tmp"
    gain=$(awk -v t="$peak" -v p="$(peak_db "$tmp")" 'BEGIN{printf "%.2f", t-p}')
    ffmpeg -hide_banner -loglevel error -y -i "$tmp" -af "volume=${gain}dB" \
        -ac 2 -ar 48000 -c:a libvorbis -q:a 5 \
        -map_metadata -1 -fflags +bitexact -flags:a +bitexact "$OUT/$ev.oga"
    rm -f "$tmp"
    printf '  %-26s <- %s\n' "$ev.oga" "$2"
}

echo "Building $OUT (Valve game audio - private use only)"
rm -f "$OUT"/*.oga
# ---- frequent, tiny, quiet ---------------------------------------------------
#    event                    source (Portal 2 sound/...)                       ss    len   fade  peak
make button-pressed           ui/p2_editor_click.wav                            0     0.07  0.02  -22
make button-pressed-modifier  ui/ui_coop_hud_focus_01.wav                       0     0.09  0.03  -22
make audio-volume-change      ui/ui_coop_hud_focus_02.wav                       0     0.12  0.04  -20
make bell                     ui/menu_invalid.wav                               0     0.16  0.04  -18
make bell-window-system       ui/hint.wav                                       0     0.20  0.05  -20
make message-new-instant      labs/ding_on.wav                                  0     0.19  0.04  -10
make message-sent-instant     ui/ui_coop_hud_unfocus_01.wav                     0     0.24  0.06  -20
make message-contact-in       ui/ui_coop_hud_activate_01.wav                    0     0.15  0.04  -18
make message-contact-out      ui/ui_coop_hud_deactivate_01.wav                  0     0.28  0.08  -18
make message-highlight        ui/p2_store_ui_add_to_cart_01.wav                 0     0.20  0.05  -16
# ---- dialogs / notifications -------------------------------------------------
make dialog-information       ui/beepclear.wav                                  0     0.40  0.10  -16
make dialog-question          ui/ui_coop_hud_click_02.wav                       0     0.42  0.12  -16
make dialog-warning           buttons/og_test_chamber_neg_01.wav                0     0.60  0.25  -17
make dialog-warning-auth      plats/door_round_blue_lock_01.wav                 0     0.55  0.15  -16
make dialog-error             buttons/button_synth_negative_01.wav              0     0.45  0.15  -14
make dialog-error-serious     weapons/portalgun/portal_invalid_surface_01.wav   0     0.60  0.20  -14
make dialog-error-critical    alarms/klaxon1.wav                                0     0.90  0.30  -14
make message-attention        props/post_message_announcer_01.wav               0     0.90  0.30  -16
# ---- tasks / outcomes --------------------------------------------------------
make completion-success       buttons/button_synth_positive_01.wav              0     0.70  0.30  -14
make completion-fail          buttons/button_synth_negative_02.wav              0     0.60  0.25  -14
make completion-partial       ui/ui_select_02.wav                               0     0.45  0.15  -18
make completion-rotation      ui/p2_editor_correction_01.wav                    0     0.45  0.12  -18
make outcome-success          buttons/og_test_chamber_pos_01.wav                0     1.20  0.50  -16
make outcome-failure          weapons/portalgun/portal_fizzle_01.wav            0     0.80  0.35  -14
make trash-empty              props/material_emancipation_01.wav                0     1.30  0.60  -16
make complete-media-burn      labs/door_open_chime_01.wav                       0     1.60  0.50  -16
make complete-media-error     buttons/button_synth_negative_02.wav              0     1.00  0.40  -14
make game-over-winner         buttons/og_test_chamber_pos_01.wav                0     2.20  0.80  -16
make game-over-loser          weapons/portalgun/portal_fizzle_01.wav            0     1.50  0.60  -14
# ---- hardware / power --------------------------------------------------------
make device-added             ui/p2_editor_konnektshun_made_01.wav              0     0.60  0.25  -14
make device-removed           ui/p2_editor_konnektshun_destroyed_01.wav         0     0.60  0.25  -14
make power-plug               ui/nv_powerup.wav                                 0     0.60  0.25  -16
make power-unplug             common/wpn_hudoff.wav                             0     0.23  0.08  -16
make media-insert-request     plats/door_round_blue_unlock_01.wav               0     0.70  0.20  -16
make battery-full             labs/door_open_chime_01.wav                       0     1.20  0.50  -18
make battery-low              ui/p2_editor_error.wav                            0     0.35  0.10  -14
make battery-caution          alarms/klaxon1.wav                                0     0.60  0.25  -16
# ---- session / services / alarms (rare) -------------------------------------
make desktop-login            weapons/portalgun/portalgun_powerup1.wav          0     1.30  0.40  -16
make desktop-logout           weapons/portalgun_powerdown.wav                   0     1.40  0.60  -14
make service-login            weapons/portalgun/portal_open_blue_01.wav         0     0.75  0.30  -16
make service-logout           weapons/portalgun/portal_close1.wav               0     0.34  0.10  -16
make alarm-clock-elapsed      props/relaxing_alarm_clock_lp_01.wav              0     2.40  0.20  -12
make phone-incoming-call      ui/beep22.wav                                     0     0.86  0.15  -12
make theme-demo               props/pre_message_announcer_01.wav                0     1.46  0.40  -14
echo "Done: $(ls "$OUT"/*.oga | wc -l) files."
