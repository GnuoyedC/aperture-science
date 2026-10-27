# Aperture OS – Launcher (Plasma 6)

Application launcher `aperture-os.launcher` in the Aperture style – a replacement for Kickoff, opened with the **Meta key**.

```text
◉ APERTURE OS
  TEST CHAMBER 01 · <hostname>
──────────────────────────────────
[ Search applications …        ]
◉ FAVORITES ──────────────── 04
  Firefox  Dolphin  kitty  PhpStorm
▸ CATEGORIES ─────────────────────
  All Applications              ›
  Development                   ›
  …
──────────────────────────────────
subject ● ONLINE   🔒 ⇥ ☾ ⟳ ⏻
```

The background is the tinted glass of the `aperture-os` Plasma Style (blur comes from KWin). Orange = focus/selection,
blue = status (ONLINE, result groups). No permanent animations, only a short fade-in when switching between
start/category/search (off with *Reduce animations*).

## Features

| Area | Behavior |
|---|---|
| Search | KRunner (like Kickoff): applications, settings, calculator, files … – max. 12 results (configurable) |
| Favorites | KActivities favorites (separate storage `aperture-os.launcher.favorites`). On first start, Firefox, Dolphin, kitty (otherwise Konsole) and PhpStorm are added. Right-click → add/remove/move |
| Categories | Menu categories, click/Enter opens, Backspace/← goes back |
| Footer | Username in lowercase, status, Lock / Log out / Sleep / Restart / Shut down (Plasma asks for confirmation as usual) |
| Keyboard | Typing searches immediately, ↑/↓ switches sections, Tab jumps between search/favorites/categories/session, Esc clears → goes back → closes |

To adopt Kickoff's favorites: in the launcher's settings, set *Favorites order from* to
`org.kde.plasma.kickoff.favorites.instance-<applet ID>`.

## Installation

```bash
./install.sh              # install/update
./install.sh --activate   # additionally replace Kickoff in all panels (restarts plasmashell)
./install.sh --deactivate # restore Kickoff
./install.sh --uninstall  # restore Kickoff + remove the package
```

`--activate` first backs up `plasma-org.kde.plasma.desktop-appletsrc` to
`~/.local/state/aperture-os/appletsrc-<time>-launcher`. The applet keeps its ID, position and its old
Kickoff settings – so `--deactivate` is lossless.

Manually: right-click the Kickoff button → *Show Alternatives …* → *Aperture Launcher*.

A launcher that is already placed only loads updates after `systemctl --user restart plasma-plasmashell`.

## Testing

```bash
plasmawindowed aperture-os.launcher     # as a window, without a panel
```

## Customization

Colors/fonts come from `tokens.json` → `tools/build.py` generates `contents/ui/Tokens.qml`.
Settings (right-click → *Configure Aperture Launcher*): icon, show favorites/categories,
number of results, favorites source, reduce animations.

> The Aperture emblem is a Portal motif (© Valve) – fan project, not covered by the GPL; see the main README.
