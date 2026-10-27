#!/usr/bin/env bash
# Aperture OS terminal dotfiles: kitty, starship, fastfetch.
#
#   ./install.sh [--only kitty|starship|fastfetch] [--force] [--alias]
#   ./install.sh --uninstall [--only ...]
#
# The files are COPIED to ~/.local/share/aperture-os/dotfiles/ (XDG_DATA_HOME is
# respected), so nothing depends on this repository checkout afterwards.
#
#   kitty      adds a marked include block to kitty.conf and quick-access-terminal.conf
#              (absolute path into the data dir); the rest of your config is untouched.
#   starship   installs ~/.config/starship.toml only if you have none. An existing file
#              is left alone unless --force is given (then it is backed up and restored
#              on uninstall). Otherwise use: export STARSHIP_CONFIG=<copied file>
#   fastfetch  never touches ~/.config/fastfetch/config.jsonc. Run: fastfetch -c <copied file>
#              (--alias prints an optional shell alias suggestion).
#
# Environment: APERTURE_NO_RELOAD=1 skips the live reload of running kitty windows.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/aperture-os/dotfiles"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/aperture-os/dotfiles"
KITTY_DIR="$CFG/kitty"
BEGIN='# >>> Aperture OS dotfiles (managed by install.sh) >>>'
END='# <<< Aperture OS dotfiles <<<'
ONLY="" MODE=install FORCE=0 ALIAS=0

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }
die() { echo "error: $*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall) MODE=uninstall ;;
        --force) FORCE=1 ;;
        --alias) ALIAS=1 ;;
        --only)
            [[ $# -ge 2 ]] || die "--only needs kitty, starship or fastfetch"
            ONLY="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done
case "$ONLY" in ""|kitty|starship|fastfetch) ;; *) die "--only must be kitty, starship or fastfetch (got '$ONLY')" ;; esac
want() { [[ -z "$ONLY" || "$ONLY" == "$1" ]]; }

reload_kitty() { [[ -n "${APERTURE_NO_RELOAD:-}" ]] || pkill -USR1 -x kitty 2>/dev/null || true; }

# copy_dir <name> <file...>: replace $DATA/<name> with a fresh copy of the repo files
copy_dir() {
    local name=$1; shift
    local f
    for f in "$@"; do [[ -f "$HERE/$name/$f" ]] || die "missing source file: $HERE/$name/$f"; done
    rm -rf "${DATA:?}/$name"
    mkdir -p "$DATA/$name"
    for f in "$@"; do cp "$HERE/$name/$f" "$DATA/$name/$f"; done
}

# remove_empty_parents: tidy up empty directories we created
prune() {
    rmdir "$DATA" 2>/dev/null || true
    rmdir "$(dirname "$DATA")" 2>/dev/null || true
    rmdir "$STATE" 2>/dev/null || true
    rmdir "$(dirname "$STATE")" 2>/dev/null || true
}

# --- managed include block (kitty) -------------------------------------------
# strip_block <file>: remove our marked block (and the blank line placed before it),
# plus the unmarked two-line block written by older versions of this installer.
strip_block() {
    local file=$1 tmp
    tmp="$(mktemp)"
    awk -v b="$BEGIN" -v e="$END" '
        function flush() { if (held) { print ""; held = 0 } }
        skip { if ($0 == e) skip = 0; next }
        $0 == b { held = 0; skip = 1; next }
        $0 == "# Aperture OS (dotfiles/install.sh)" { legacy = 1; next }
        legacy && $0 ~ /^include aperture(-quick-access)?\.conf$/ { legacy = 0; next }
        { legacy = 0 }
        $0 == "" { flush(); held = 1; next }
        { flush(); print }
        END { flush() }
    ' "$file" > "$tmp"
    cat "$tmp" > "$file"   # keep permissions/ownership of the original
    rm -f "$tmp"
}

# add_block <file> <include-path> <tag>
add_block() {
    local file=$1 inc=$2 tag=$3 want existing
    want="$BEGIN"$'\n'"include $inc"$'\n'"$END"
    mkdir -p "$(dirname "$file")"
    if [[ ! -e "$file" ]]; then
        : > "$file"
        : > "$STATE/$tag.created"
    fi
    existing="$(awk -v b="$BEGIN" -v e="$END" '$0==b{p=1} p{print} $0==e{p=0}' "$file")"
    if [[ "$existing" == "$want" ]]; then
        echo "  $(basename "$file"): include already present"
        return
    fi
    strip_block "$file"
    [[ -s "$file" && -n "$(tail -c1 "$file")" ]] && echo >> "$file"
    [[ -s "$file" ]] && echo >> "$file"
    printf '%s\n' "$want" >> "$file"
    echo "  $(basename "$file"): include added"
}

# drop_block <file> <tag>: independent of any other file
drop_block() {
    local file=$1 tag=$2
    [[ -f "$file" ]] || return 0
    if grep -qxF "$BEGIN" "$file" || grep -qxF '# Aperture OS (dotfiles/install.sh)' "$file"; then
        strip_block "$file"
        echo "  $(basename "$file"): include removed"
    fi
    if [[ -e "$STATE/$tag.created" ]]; then
        # we created the file: remove it again if nothing else was added to it
        [[ -n "$(tr -d '[:space:]' < "$file")" ]] || { rm -f "$file"; echo "  $(basename "$file"): removed (was created by installer)"; }
        rm -f "$STATE/$tag.created"
    fi
}

is_legacy_link() { [[ -L "$1" && "$(readlink "$1")" == */dotfiles/* ]]; }

# --- install -----------------------------------------------------------------
install_kitty() {
    echo "kitty"
    copy_dir kitty aperture.conf aperture-quick-access.conf
    add_block "$KITTY_DIR/kitty.conf" "$DATA/kitty/aperture.conf" kitty
    add_block "$KITTY_DIR/quick-access-terminal.conf" "$DATA/kitty/aperture-quick-access.conf" kitty-qa
    # symlinks from older versions pointed into the repo
    local l
    for l in aperture.conf aperture-quick-access.conf; do
        if is_legacy_link "$KITTY_DIR/$l"; then rm "$KITTY_DIR/$l"; echo "  removed old symlink $l"; fi
    done
    reload_kitty
}

install_starship() {
    echo "starship"
    copy_dir starship aperture.toml
    local src="$DATA/starship/aperture.toml" dst="$CFG/starship.toml"
    if is_legacy_link "$dst"; then
        rm "$dst"   # old symlink into the repo; the user's original is in the pre-aperture backup
        [[ -e "$CFG/starship.pre-aperture.toml" && ! -e "$STATE/starship.toml.orig" ]] && \
            { mkdir -p "$STATE"; mv "$CFG/starship.pre-aperture.toml" "$STATE/starship.toml.orig"; }
    fi
    if [[ ! -e "$dst" ]]; then
        mkdir -p "$CFG"
        cp "$src" "$dst"
        echo "  installed $dst"
    elif cmp -s "$src" "$dst"; then
        echo "  $dst is already up to date"
    elif [[ $FORCE -eq 1 ]]; then
        [[ -e "$STATE/starship.toml.orig" ]] || cp -a "$dst" "$STATE/starship.toml.orig"
        cp "$src" "$dst"
        echo "  replaced $dst (backup: $STATE/starship.toml.orig)"
    else
        echo "  $dst already exists - left untouched."
        echo "  To try Aperture in a shell:   export STARSHIP_CONFIG=\"$src\""
        echo "  To make it permanent: add that line to your shell rc, or re-run with --force"
        echo "  (backs up your file and restores it on --uninstall)."
    fi
}

install_fastfetch() {
    echo "fastfetch"
    copy_dir fastfetch config.jsonc aperture-logo.txt aperture-logo-blocks.txt aperture-logo.png
    # the generated config references ~/.config/fastfetch/...; point it at the copied files
    local cfg="$DATA/fastfetch/config.jsonc" tmp
    tmp="$(mktemp)"
    sed "s#~/\.config/fastfetch/#$DATA/fastfetch/#g" "$cfg" > "$tmp"
    cat "$tmp" > "$cfg"; rm -f "$tmp"
    # symlinks from older versions pointed into the repo; keep the config active as a copy
    local l
    if is_legacy_link "$CFG/fastfetch/config.jsonc"; then
        rm "$CFG/fastfetch/config.jsonc"; cp "$cfg" "$CFG/fastfetch/config.jsonc"
        echo "  replaced old symlink config.jsonc with a copy"
    fi
    for l in aperture-logo.txt aperture-logo.png; do
        if is_legacy_link "$CFG/fastfetch/$l"; then rm "$CFG/fastfetch/$l"; echo "  removed old symlink $l"; fi
    done
    echo "  installed to $DATA/fastfetch (your ~/.config/fastfetch is untouched)"
    echo "  Try it:   fastfetch -c \"$cfg\""
    if [[ $ALIAS -eq 1 ]]; then
        echo "  Optional alias for your shell rc:"
        echo "    alias fastfetch='fastfetch -c \"$cfg\"'"
    else
        echo "  (re-run with --alias to print an optional shell alias)"
    fi
}

# --- uninstall ---------------------------------------------------------------
uninstall_kitty() {
    echo "kitty"
    drop_block "$KITTY_DIR/kitty.conf" kitty
    drop_block "$KITTY_DIR/quick-access-terminal.conf" kitty-qa
    local l
    for l in aperture.conf aperture-quick-access.conf; do
        if is_legacy_link "$KITTY_DIR/$l"; then rm "$KITTY_DIR/$l"; echo "  removed old symlink $l"; fi
    done
    rm -rf "${DATA:?}/kitty"
    reload_kitty
}

uninstall_starship() {
    echo "starship"
    local dst="$CFG/starship.toml" ours="$DATA/starship/aperture.toml" bak="$STATE/starship.toml.orig"
    if is_legacy_link "$dst"; then
        rm "$dst"; echo "  removed old symlink starship.toml"
    elif [[ -e "$dst" && -f "$ours" ]] && cmp -s "$ours" "$dst"; then
        rm "$dst"; echo "  removed $dst"
    elif [[ -e "$dst" && ! -e "$bak" ]]; then
        echo "  $dst is not the Aperture file - left untouched"
    fi
    if [[ -e "$bak" ]]; then
        if [[ ! -e "$dst" ]]; then
            mv "$bak" "$dst"; echo "  restored $dst"
        else
            echo "  $dst was modified since install - not overwritten; backup kept at $bak"
        fi
    elif [[ ! -e "$dst" && -e "$CFG/starship.pre-aperture.toml" ]]; then
        mv "$CFG/starship.pre-aperture.toml" "$dst"; echo "  restored $dst"
    fi
    rm -rf "${DATA:?}/starship"
}

uninstall_fastfetch() {
    echo "fastfetch"
    local l
    for l in config.jsonc aperture-logo.txt aperture-logo.png; do
        if is_legacy_link "$CFG/fastfetch/$l"; then rm "$CFG/fastfetch/$l"; echo "  removed old symlink $l"; fi
    done
    rm -rf "${DATA:?}/fastfetch"
    echo "  removed $DATA/fastfetch"
}

if [[ $MODE == install ]]; then
    mkdir -p "$STATE"
    want kitty && install_kitty
    want starship && install_starship
    want fastfetch && install_fastfetch
    echo "done. Files: $DATA   Backups/state: $STATE"
else
    want kitty && uninstall_kitty
    want starship && uninstall_starship
    want fastfetch && uninstall_fastfetch
    prune
    echo "done."
fi
