# Aperture OS – Conventions for all components

Every component (`colors/`, `plasma-style/`, `aurorae/`, …) is a self-contained folder in the monorepo and must be
installable without the rest (so it can be split off later with `git subtree split`).

## Required contents of every component

| File | Purpose |
|---|---|
| `README.md` | What it is, installation, activation, uninstallation, customization |
| `install.sh` | `./install.sh` installs to `~/.local/...` (never to `/usr` without an explicit reason); `./install.sh --uninstall` removes **only** its own files. Optional `--activate`. Bash, `set -euo pipefail`, idempotent. |
| `tokens.json` | Copy of `design/tokens.json` from the main repo (kept in sync by `tools/build-all.sh`) |
| `tools/build.py` | (if files are generated) reads **only** `tokens.json`, Python standard library only. Exception for images: `cursors`, `plymouth` and `wallpaper/tools` may use Pillow (`tools/build-all.sh` skips them without Pillow) |
| `.gitignore` | |

Generated files are committed so the repo can be installed without a build. The build must be reproducible: CI
rebuilds everything and fails if any committed text file changes.
Before committing, run `tools/build-all.sh` and `tools/lint.sh`.

## Design tokens

Colors, transparencies, radii, fonts and animation durations come **exclusively** from `tokens.json`.
Do not invent your own color values – if a value is missing, add it to `design/tokens.json`.

Color logic: **Orange = interaction/focus/active**, **Blue = info/system status/technical**,
**Green = success**, **Amber = warning**, **Red = error**. Do not make orange and blue glow everywhere at the same time.
Never communicate states through color alone (add text, an icon or a shape).

## Style

Industrial test facility, calm HMI, tinted safety glass. No neon, no gamer look,
no large glows, minimal radii (2–3 px), thin 1 px lines.
Fonts: UI `Inter` (fallback `Noto Sans`), technical labels `JetBrains Mono` (fallback `IBM Plex Mono`), used only as an accent.

## Runtime

Native QML/Qt/KDE. No Node, no Electron, no permanent background processes, no effects that permanently
load the CPU/GPU. Animations respect `motion.reduceMotion`.

## IDs / names

| Component | ID |
|---|---|
| Global theme | `aperture-os` (Look-and-Feel) |
| Plasma style | `aperture-os` |
| Color scheme | `ApertureOS` |
| Aurorae | `aperture-os` |
| Splash | `aperture-os.splash` |
| Wallpaper plugin | `aperture-os.chamber` |
| Widgets | `aperture-os.testchamber`, `aperture-os.sysmonitor`, `aperture-os.notice` |
| Launcher | `aperture-os.launcher` |
| Lock screen shell | `aperture-os.shell` |
| Plymouth | `aperture-os` (`/usr/share/plymouth/themes/aperture-os`) |
| SDDM | `aperture-protocol` |
| Sound theme | `aperture-os` |
| Cursor | `Aperture-cursors` |

## Official Portal assets

Valve-owned assets (sounds, logos and similar material from Portal) are fan-project material. They are not
covered by the GPL and are credited in the README. Each component that contains such assets says so in its own
README. Where possible, also provide a fetch script that regenerates the assets reproducibly.

## Language (i18n)

The system language decides; German and English are supported.

- **Plasmoids:** Source strings in `i18n("…")` are **English** (KDE treats en_US as the source language and
  never loads an English catalog). German lives in `<component>/po/de/plasma_applet_<id>.po`;
  `tools/build-l10n.py` compiles it to `<id>/contents/locale/de/LC_MESSAGES/` (committed, and installed along with
  the package by `kpackagetool6`). Instances that are already placed only load new catalogs after plasmashell is restarted.
- **Lab texts** (`TEST CHAMBER 01`, `STATUS: LOCKED`, splash steps …) deliberately stay in English.
- Always format date/time through `Qt.locale()`, never with a fixed German pattern.
- Non-plasmoid QML without a gettext domain (e.g. SDDM): use a `Strings.qml` table, selected via `Qt.locale().name`.
