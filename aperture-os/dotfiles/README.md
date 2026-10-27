# Aperture OS – Terminal dotfiles (kitty · Starship · fastfetch)

The files here are the **versioned source**. `install.sh` **copies** them to
`~/.local/share/aperture-os/dotfiles/` (`$XDG_DATA_HOME` is respected), so nothing on your system depends on
the repo checkout afterwards. Re-run the installer to update.

| Component | Installed to | Effect on your config |
|---|---|---|
| kitty | `…/dotfiles/kitty/` | A marked `include` block (absolute path) is appended to `kitty.conf` and `quick-access-terminal.conf`; nothing else is changed |
| starship | `…/dotfiles/starship/aperture.toml` | Copied to `~/.config/starship.toml` **only if you have none**; otherwise untouched (see below) |
| fastfetch | `…/dotfiles/fastfetch/` (config, logos) | `~/.config/fastfetch` is never touched; run `fastfetch -c <path>` |

`kitty/aperture.conf`, `starship/aperture.toml` and `fastfetch/*` are generated from `design/tokens.json`
(`tools/build-dotfiles.py` in the main repo). Do not edit them directly – otherwise the
next build overwrites your change. Your own settings belong in `kitty.conf` or see below.

## Installation

```bash
./install.sh                      # everything
./install.sh --only kitty         # one component (kitty | starship | fastfetch)
./install.sh --force              # starship: back up and replace an existing starship.toml
./install.sh --alias              # fastfetch: also print an optional shell alias
./install.sh --uninstall          # remove everything again (also with --only)
```

The script is idempotent. Running kitty windows reload immediately (SIGUSR1; skip with `APERTURE_NO_RELOAD=1`).
Backups and state: `~/.local/state/aperture-os/dotfiles/`.

### kitty

`kitty.conf` and `quick-access-terminal.conf` each get this block (each handled independently, also on uninstall):

```text
# >>> Aperture OS dotfiles (managed by install.sh) >>>
include /home/you/.local/share/aperture-os/dotfiles/kitty/aperture.conf
# <<< Aperture OS dotfiles <<<
```

* The block is at the **end**: later values win, so Aperture overrides older colors while your font, size and
  ligatures are kept. Put your own overrides below the block if they should win.
* kitty does **not** allow comments after values (`include x  # ...` is read as a file name).
* Uninstall removes exactly that block (and deletes a file the installer itself created, if it is otherwise empty).
* Contents: background `#070B0F` at 88 % opacity + blur (`background_blur 24`, works under KWin/Wayland),
  orange cursor, muted orange selection, ANSI palette (magenta = Aperture orange), flat tab bar
  with orange active tab text, orange border on the active split.
* Change transparency live: `ctrl+shift+a` then `m`/`l` (dynamic_background_opacity is enabled).

### Starship

* No `~/.config/starship.toml`: the Aperture file is installed there.
* Existing file: it is **not** replaced. Use Aperture per shell or permanently via
  `export STARSHIP_CONFIG="$HOME/.local/share/aperture-os/dotfiles/starship/aperture.toml"` (shell rc).
* `--force`: your file is backed up to `~/.local/state/aperture-os/dotfiles/starship.toml.orig` and replaced;
  `--uninstall` restores it (if you edited the installed file since, it is kept and the backup stays in place).
* `~/.zshrc` must still contain `eval "$(starship init zsh)"`.

```text
◉ user@host ~/projects/foo  main !1 php 8.3 ddev took 3s
❯
```

| Color | Meaning |
|---|---|
| Orange | Path, prompt character |
| Cyan/blue | Git branch and status, ddev |
| Gray | Host, versions, Docker, duration |
| Red | Exit code ≠ 0 (`✕ 1`), prompt character after an error, root user |

Modules: user, host, directory, git, custom php, nodejs, custom ddev, docker_context, cmd_duration. Inside a ddev
project (also in subdirectories) the PHP version is read from `php_version` in `.ddev/config.yaml` instead of the
host `php`. Both custom modules start a non-login bash (`bash --noprofile --norc`), which is much faster than `bash -lc`.

### fastfetch

Your `~/.config/fastfetch/config.jsonc` is never overwritten. The preset lives in
`~/.local/share/aperture-os/dotfiles/fastfetch/`; the installer rewrites the logo path in the copied
`config.jsonc` so it points to the copied `aperture-logo.txt`.

```bash
fastfetch -c ~/.local/share/aperture-os/dotfiles/fastfetch/config.jsonc
alias fastfetch='fastfetch -c ~/.local/share/aperture-os/dotfiles/fastfetch/config.jsonc'   # optional
```

Shows the Aperture logo and the system data as a "Test Chamber" status block. Other logo variants in the same
directory: `aperture-logo-blocks.txt` (half-block iris) and `aperture-logo.png` (for the kitty graphics protocol,
e.g. `fastfetch -c <config> --logo-type kitty-direct --logo <dir>/aperture-logo.png`).

### Uninstall

`./install.sh --uninstall` removes the kitty blocks, the copied files, and an installed starship.toml
(restoring a backup if `--force` was used). Symlinks left by older versions of the installer are removed too.

## Customization

* Colors: change `design/tokens.json` in the main repo, then run `tools/build-dotfiles.py`.
* Personal kitty options (font, shortcuts …) belong in `~/.config/kitty/kitty.conf` – **above**
  the Aperture block if Aperture may override them, **below** it if your values should win.
* To add Starship modules: in the generator `tools/build-dotfiles.py` (function `starship()`).
