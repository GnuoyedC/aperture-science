# Aperture OS – Color scheme

KDE color scheme **Aperture OS** (`ApertureOS.colors`) for applications (Breeze), Dolphin, dialogs and menus.

| Role | Color |
|---|---|
| Window / view | `#0D151C` / `#070B0F` |
| Text / muted | `#D9E3E8` / `#81939E` |
| Selection, focus, hover (interaction) | Aperture Orange `#FF7800`, text on it `#0A0E12` |
| Links, info | Portal Blue `#00AEEF` |
| Positive / neutral / negative | `#4FD18B` / `#FFB000` / `#FF4545` |

All text/background pairs meet WCAG AA.

## Installation

```bash
./install.sh              # to ~/.local/share/color-schemes
./install.sh --activate   # + activate (plasma-apply-colorscheme ApertureOS)
./install.sh --uninstall  # remove; if it was active, BreezeDark is set
```

Or: System Settings → Colors & Themes → Colors → *Aperture OS*.

## Customization

The file is generated from `tokens.json` – do not edit it by hand:

```bash
python3 tools/build.py   # reads tokens.json, writes ApertureOS.colors
```

In the main repo, the tokens are maintained centrally in `design/tokens.json` and distributed with `tools/build-all.sh`.
