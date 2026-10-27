#!/usr/bin/env bash
# fetch_portal_sounds.sh - (re)builds sounds/portal/*.wav from original Portal 2 SFX.
#
# !! The resulting files are Valve Corporation game material (Portal 2, (c) Valve).
# !! They are fetched for PRIVATE, PERSONAL USE ONLY on your own machine.
# !! Do NOT commit, package or redistribute sounds/portal/ with this theme.
#
# Sources (no voice lines, SFX only):
#   - github.com/sourcesounds/portal2 (raw dump of Portal 2's sound/ tree),
#     pinned to a fixed commit so the result is reproducible.
#   (The Portal Wiki only hosts MP3 re-encodes of a few of these, e.g.
#    Portal2_sfx_button_positive.mp3; the lossless WAVs are used instead.)
#
# Output: 16-bit PCM mono WAV (QtMultimedia SoundEffect needs WAV), 44.1 kHz
# (ambience 22.05 kHz), leading silence trimmed, length-trimmed with a short
# fade-out, peak-normalised (UI ticks quiet, ambience very quiet).
#
# Requires: bash, curl, ffmpeg. Usage: tools/fetch_portal_sounds.sh [--keep-raw]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/sounds/portal"
RAW="$(mktemp -d)"
[[ "${1:-}" == "--keep-raw" ]] && echo "raw files kept in $RAW" || trap 'rm -rf "$RAW"' EXIT

COMMIT=36edc8b85c4b5718289f56d8c3652a6dc0e58a1b
BASE="https://raw.githubusercontent.com/sourcesounds/portal2/$COMMIT/sound"

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

normalise() { # normalise <tmp in> <out> <target peak dBFS> <rate>
    local gain
    gain=$(awk -v t="$3" -v p="$(peak_db "$1")" 'BEGIN{printf "%.2f", t-p}')
    ffmpeg -hide_banner -loglevel error -y -i "$1" -af "volume=${gain}dB" \
        -ac 1 -ar "$4" -c:a pcm_s16le "$2"
}

# make <slot> <repo path> <start offset s> <length s> <fade-out s> <peak dBFS> [rate]
make() {
    local slot=$1 src; src=$(fetch "$2")
    local ss=$3 len=$4 fade=$5 peak=$6 rate=${7:-44100}
    local tmp="$RAW/$slot.tmp.wav"
    ffmpeg -hide_banner -loglevel error -y -ss "$ss" -i "$src" -af \
"aformat=sample_fmts=flt:channel_layouts=mono,\
silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.005,\
atrim=0:${len},asetpts=N/SR/TB,\
afade=t=out:st=$(awk -v l="$len" -v f="$fade" 'BEGIN{print (l-f<0)?0:l-f}'):d=${fade}" \
        -ar "$rate" -c:a pcm_s16le "$tmp"
    normalise "$tmp" "$OUT/$slot.wav" "$peak" "$rate"
    rm -f "$tmp"
    printf '  %-20s <- %s\n' "$slot.wav" "$2"
}

# Seamless loop: take <len> s starting at <ss>, then crossfade the <xf> s that
# follow the segment into its head, so the end flows back into the start.
make_loop() { # make_loop <slot> <repo path> <start s> <length s> <xfade s> <peak> <rate>
    local slot=$1 src; src=$(fetch "$2")
    local ss=$3 len=$4 xf=$5 peak=$6 rate=$7
    local tmp="$RAW/$slot.tmp.wav"
    ffmpeg -hide_banner -loglevel error -y -ss "$ss" -t "$(awk -v l="$len" -v x="$xf" 'BEGIN{print l+x}')" -i "$src" \
        -filter_complex \
"[0:a]aformat=sample_fmts=flt:channel_layouts=mono,asplit=3[a][b][c];\
[a]atrim=0:${xf},asetpts=N/SR/TB,afade=t=in:d=${xf}[head];\
[b]atrim=${len}:$(awk -v l="$len" -v x="$xf" 'BEGIN{print l+x}'),asetpts=N/SR/TB,afade=t=out:d=${xf}[tail];\
[head][tail]amix=inputs=2:normalize=0[intro];\
[c]atrim=${xf}:${len},asetpts=N/SR/TB[body];\
[intro][body]concat=n=2:v=0:a=1[out]" \
        -map "[out]" -ar "$rate" -c:a pcm_s16le "$tmp"
    normalise "$tmp" "$OUT/$slot.wav" "$peak" "$rate"
    rm -f "$tmp"
    printf '  %-20s <- %s (loop)\n' "$slot.wav" "$2"
}

echo "Building $OUT (Valve game audio - private use only)"
#    slot             source (Portal 2 sound/...)                  ss   len   fade  peak
make boot_start      plats/breaker_room_bootup_01.wav              0    3.0   0.8   -6
make system_ready    labs/ding_on.wav                              0    0.19  0.03  -6
make ui_focus        ui/ui_coop_hud_focus_01.wav                   0    0.09  0.02  -14
make ui_click        ui/buttonclick.wav                            0    0.21  0.05  -14
make ui_error        ui/menu_invalid.wav                           0    0.16  0.03  -6
make portal_activate weapons/portalgun/portal_open_blue_01.wav     0    0.75  0.15  -6
make login_success   buttons/button_synth_positive_01.wav          0    1.4   0.3   -6
make login_failure   buttons/button_synth_negative_02.wav          0    1.0   0.3   -6
make_loop ambience_loop ui/p2_editor_drone_lp_01.wav               2.0  12.0  1.5   -24  22050
echo "Done."
