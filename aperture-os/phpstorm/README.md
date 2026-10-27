# Aperture OS – PhpStorm Theme

UI theme and editor color scheme "Aperture OS" for PhpStorm 2026.2 (Islands UI).
A calm, industrial test-facility look: dark surfaces, orange for interaction/focus,
blue for information – designed for long working days (contrast and eye comfort over effect).

All colors come from `tokens.json` (a copy of `design/tokens.json` in the main repo) or are
blended from it in the build script.

## Contents

| File | Purpose |
|---|---|
| `tokens.json` | Design tokens (the only color source) |
| `tools/build.py` | generates the theme, color scheme, `plugin.xml` and the plugin JAR (Python stdlib only) |
| `resources/aperture-os.theme.json` | UI theme (parent: "Islands Dark") |
| `resources/ApertureOS.icls` | Editor color scheme (parent: Darcula); can also be imported manually |
| `resources/META-INF/plugin.xml` | Plugin descriptor (`themeProvider` + `bundledColorScheme`) |
| `dist/aperture-os-theme.jar` | finished plugin |
| `install.sh` | install / uninstall |

## Installation

```bash
./install.sh
```

Copies `dist/aperture-os-theme.jar` to `~/.local/share/JetBrains/PhpStorm2026.2/`
(the plugin directory of PhpStorm 2026.2). To use a different path:
`PHPSTORM_PLUGINS_DIR=/path ./install.sh`.

The script does not change any PhpStorm settings and does not close a running PhpStorm.
Afterwards **restart** PhpStorm (the plugin is only loaded at startup).

## Activation

1. **Settings → Appearance & Behavior → Appearance → Theme:** `Aperture OS`
2. **Settings → Editor → Color Scheme → Scheme:** `Aperture OS`
   (normally set automatically when you switch the theme)

The theme requires the Islands UI (the default in PhpStorm 2026.x). If the classic
UI is active, it does not show up in the list.

## Recommended font

**Settings → Editor → Font**

- Font: **JetBrains Mono** (bundled with PhpStorm)
- Size: **14**
- Line height: **1.2**
- Ligatures to taste

The color scheme deliberately does not set a font, so your own settings are preserved.

## Color logic in the editor

| Element | Color |
|---|---|
| Keywords | Orange |
| Classes / types | Light blue (cyan) |
| Functions / methods | Blue, calls lighter |
| Strings | Green (muted) |
| Numbers / constants | Amber |
| Comments | Muted gray (italic) |
| Errors / warnings | Red / amber (wavy underline + scrollbar marker) |
| Selection | Muted orange tone |
| Search matches | Amber background |

Every syntax color has a contrast ratio of at least 4.5:1 against the editor background; otherwise the build aborts.
Console ANSI colors are mapped to the Aperture palette (magenta → orange).

## Uninstallation

```bash
./install.sh --uninstall
```

Removes only `aperture-os-theme.jar`. Switch to another theme in PhpStorm first
(otherwise PhpStorm falls back to the default theme on its own after the restart).

## Customization

1. Change colors in `tokens.json` (or in the main repo's `design/tokens.json` and sync it) –
   or change the mappings in `tools/build.py` (sections `P` = syntax palette, `B` = editor backgrounds,
   `colors`/`ui` = interface, `attrs` = individual highlighting keys).
2. Rebuild and install:

   ```bash
   python3 tools/build.py
   ./install.sh
   ```

3. Restart PhpStorm.

Generated files (`resources/`, `dist/`) are checked in so the repo can be installed
without a build.

You can also override individual colors directly in PhpStorm (Settings → Editor → Color Scheme);
PhpStorm then creates its own copy `_@user_Aperture OS`, which the build does not overwrite.
