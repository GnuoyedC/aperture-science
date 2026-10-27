# Aperture OS – Global Theme

Look-and-feel package **Aperture OS** (`aperture-os`). When applied, the following are set:

| Area | Value |
|---|---|
| Color scheme | ApertureOS |
| Application style | Breeze |
| Plasma Style | aperture-os |
| Window decoration | Aurorae aperture-os, border size Normal |
| Splash screen | Aperture OS (included in the package, source: repo `aperture-splash`) |
| Wallpaper | ApertureTestChamber |

**Deliberately not set:** icons, cursor (recommended: Aperture-cursors via `cursors/install.sh --activate`), panel/desktop layout.

## Installation

```bash
./install.sh              # install the package + Aperture icon (aperture-os.svg)
./install.sh --activate   # apply
./install.sh --uninstall  # remove (choose a different Global Theme first)
```

Requires the components `colors`, `plasma-style`, `aurorae`, `wallpaper` (the main repo installs everything).

## Optional Aperture panel

One bottom panel **per screen**, no top panel (matches the reference setup):

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ ◉ │ 1 2 3 4 │  Firefox  Dolphin  Kitty  …              │ Tray │ 14:37 │ ▭ │
└──────────────────────────────────────────────────────────────────────────┘
```

* ◉ = Aperture launcher `aperture-os.launcher` (Meta opens it). If it is missing, Kickoff is used.
* Height 45, floating, **translucent**. Plasma scripting can only read the panel mode (`panel.opacity`),
  so `--apply-layout` afterwards writes `panelOpacity=2` to `plasmashellrc`. This takes effect after
  `systemctl --user restart plasma-plasmashell`.
* ▭ = Minimize all windows.

```bash
./install.sh --apply-layout     # REPLACES all panels, backs up the panel configuration first
./install.sh --restore-layout   # restore the latest backup (restarts plasmashell)
```

The script reports for each panel which screen it ended up on. The layout lives in
`layouts/aperture-panel-layout.js` (Plasma desktop scripting) and can be freely customized.
To swap only the launcher without replacing the panels: `launcher/install.sh --activate`.

## Syncing the splash

When applying a Global Theme, Plasma sets the splash screen to the theme itself. This package therefore
contains a copy of the splash. After changes in the splash repo: `tools/sync-splash.sh`.
