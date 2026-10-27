# Aperture OS – Window decoration

Aurorae decoration **Aperture OS**:

```text
┌──────────────────────────────────────┐   active:   1-px border in muted orange,
│ ◉ Dolphin                    − □ ×   │             short orange accent line at the top left
├──────────────────────────────────────┤   inactive: blue-gray border
│              CONTENT                 │   Shadow: 8 px, soft, no glow
└──────────────────────────────────────┘
```

* dark title bar (`#070B0F`), title on the left, app icon on the left, buttons on the right (− □ ×)
* Hover: orange icon; close hover: red
* maximized: no border and no shadow

## Installation

```bash
./install.sh              # to ~/.local/share/aurorae/themes/aperture-os
./install.sh --activate   # + activate, border size "Normal" (= 1-px line all around)
./install.sh --uninstall  # remove; if it was active, Breeze is set
```

Or: System Settings → Colors & Themes → Window Decorations → *Aperture OS*.
The border size "No Side Borders" hides the side accent lines.

## Customization

`tools/build.py` generates all SVGs and `aperture-osrc` from `tokens.json` (button layout, title height,
shadow `PAD`/`SHADOW` at the top of the script).

**KWin cache:** Aurorae does not reload a theme that is already active. After making changes, briefly select a different
decoration and switch back (or log out and back in).
