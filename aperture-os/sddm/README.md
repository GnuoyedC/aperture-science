# Aperture Protocol – SDDM Theme

An animated login screen inspired by Aperture Laboratories/Portal for **SDDM on KDE Plasma 6 (Qt 6, theme API 2.0)**.
The computer sits in an abandoned test chamber, and the control console is the Linux login.

![Preview](assets/preview.jpg)

## Features

| State | Behavior |
|---|---|
| **Boot** | Terminal initialization (~2.6 s, *any key / click skips it*), then the console glides in |
| **Login** | Ring rotates very slowly, orange segments pulse, blue core "breathes", light/fog drift, portal flicker, HUD status change every 9 s |
| **Authentication** | Ring rotates faster, iris closes slightly, progress bar in the button, timeout after 20 s → never gets stuck |
| **Success** | Blue flash, ring and core turn blue, "TEST SEQUENCE INITIALIZED", UI fades out in < 1 s |
| **Error** | ~300 ms glitch (offset, red bars, red flash), red core, "TEST SEQUENCE FAILED" banner, automatically back after 4.5 s |
| **Standby** | After 90 s without input: console off, background dimmed, clock stays, "STANDBY TEST MODE", mouse/key wakes it |
| **Power menu** | Shut down / restart / hibernate (/ suspend) as a confirmation dialog, keyboard (↑↓, Enter, Esc) |

Also: user list (dropdown), show password, caps lock hint, session and keyboard layout selection,
PAM info messages, clock/date/host in the HUD, multi-monitor (console only on the primary screen), sound effects.

## Installation

```bash
sudo ./install.sh                 # installs to /usr/share/sddm/themes/aperture-protocol and activates it
sudo ./install.sh --no-activate   # install only, select it via System Settings
sudo ./install.sh --uninstall
```

Activation happens through `/etc/sddm.conf.d/90-aperture-protocol.conf` (`[Theme] Current=aperture-protocol`); existing configuration files are not touched.
The Qt 6 QML modules `QtQuick`, `QtQuick.Controls`, `QtQuick.Shapes` and optionally `QtMultimedia` are required
(Debian/Ubuntu: `qml6-module-qtquick-controls qml6-module-qtquick-shapes qml6-module-qtmultimedia`; usually already installed with Plasma 6).

## Testing

**1. Real greeter in test mode** (opens a window and does not log anything out):

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/aperture-protocol
# or directly from the source folder:
sddm-greeter-qt6 --test-mode --theme ./aperture-sddm
```

There is no SDDM daemon in test mode. Real logins are therefore not possible (after 20 s a timeout error appears, which is intended), and the power buttons are hidden because SDDM reports `canPowerOff=false`.

**2. Development preview with simulated SDDM** (`pip install PySide6`):

```bash
python3 tools/preview.py --size 2560x1440                 # password "portal" = success, anything else = error
QT_QPA_PLATFORM=offscreen python3 tools/preview.py --set bootSequence=false \
    --script '1200:type:wrong\n' --shot 2600:error.png --quit 3000
```

The script can trigger errors, success, standby, keyboard and mouse input, and produce screenshots at any resolution (see the top of `tools/preview.py`).

**Recommended checklist:** skip boot (key) · wrong password → glitch and return · empty user name → hint · switch session · wait for standby or set `idleTimeout=10` · open the power menu and close it with Esc · caps lock · then a real login.

## Customization

All values are in `theme.conf`. Local changes can also go in `theme.conf.user`, which SDDM reads with priority.

| Area | Keys |
|---|---|
| Colors | `colorBase`, `colorPanel`, `colorField`, `colorLine`, `colorText`, `colorMuted`, `colorOrange`, `colorOrangeBright`, `colorBlue`, `colorBlueBright`, `colorError`, `colorButtonText` |
| Font / size | `fontFamily`, `monoFamily`, `fontSize`, `uiScale` (additional factor on top of the automatic scaling) |
| Background | `background` (relative to the theme or absolute), `backgroundDim`, `showGrid`, `showScanlines`, `sceneGlows` + `coreX/coreY/portalX/portalY` (relative position of the robot eye and portal in the image) |
| Animation | `reduceMotion` (turns off all continuous animations), `bootSequence`, `bootDuration`, `idleTimeout` (s, 0 = off), `authTimeout` (s) |
| Behavior | `showUserList`, `clearPasswordOnStandby` |
| Sound | `sounds`, `soundPack` (`portal` / `synth`), `soundVolume` (0–1), `ambience` (quiet facility hum, off by default) |
| Texts | `language` (`de`, `en`, `auto`), `chamberId`, `osName` |

**Texts and localization:** All texts live in `components/Strings.qml`. The UI texts are in one table per language (`de`, `en`), and the lab texts (boot sequence, HUD messages, status lines) are in the shared `lab` table. A language table can override any `lab` key, e.g. `"boot.welcome": "WILLKOMMEN, TESTSUBJEKT"`. For a new language, add a table and set `language=<code>`.

**Animations:** Timings are set directly on the animations in the components (e.g. ring rotation 240 s / 150 s in `ApertureRing.qml`, glitch sequence in `Main.qml`, status change 9 s in `HudStatus.qml`). Global duration tokens (`fast`, `normal`, `slow`) are in `components/Theme.qml`.

**Sounds:** To provide replacement sounds, put WAV files with the same names in `sounds/<pack>/`. If a file is missing from the selected pack, the theme automatically uses the file from `sounds/synth/`.

## Structure

```
Main.qml                     state machine (boot/login/auth/success/error + standby), SDDM signals, layout
components/
  Theme.qml                  design tokens + config parsing + resolution scaling
  Strings.qml                all texts, language tables
  ChamberBackground.qml      background image + color grading, light/fog drift, grid, scanlines, vignette
  CoreWidget.qml             breathing core glow (robot eye, emblem center, standby)
  GlowBlob.qml               radial vector glow (basis of all light effects)
  ApertureRing.qml           central emblem: logo, calibration ring, tick ring
  LoginPanel.qml             login console (status, fields, button, session/layout, user list)
  ConsoleField.qml           input field with orange focus glow
  ConsoleComboBox.qml        dropdown in console style
  HudStatus.qml              chamber ID, clock, date, system status
  BootSequence.qml           initialization sequence
  StandbyScreen.qml          standby view
  PowerMenu.qml              system/power dialog
  SoundPlayer.qml            QtMultimedia sounds (optional via Loader)
assets/                      background.jpg, background-chamber.jpg, aperture-logo.svg, scanlines.png, icons/*.svg, preview.jpg
sounds/portal|synth/         sound packs (WAV)
tools/                       preview.py, generate_logo.py, generate_sounds.py, fetch_portal_sounds.sh
```

## Assets

| Asset | Size | Why a file |
|---|---|---|
| `assets/background.jpg` | 2560×1440 | Research complex in a storm (default, `sceneGlows=false`). Photorealistic motifs cannot sensibly be generated procedurally. |
| `assets/background-chamber.jpg` | 267 KB, 1672×941 | The original test chamber; use it together with `background=assets/background-chamber.jpg` and `sceneGlows=true`. |
| `assets/aperture-logo.svg` | < 1 KB | Vector iris (8 blades). Generated geometrically by `tools/generate_logo.py` and scales losslessly. |
| `assets/icons/*.svg` | < 0.5 KB each | 15 line icons (user, lock, eye, power …), scalable |
| `assets/scanlines.png` | 70 B | 1×4 px tile. The GPU tiles it, which is cheaper than thousands of line items. |
| `sounds/portal/*.wav` | 1.2 MB | Original SFX from Portal 2 (breaker room boot-up, portal open, button positive/negative, UI clicks, editor drone). QtMultimedia `SoundEffect` only plays WAV. Regenerate with `tools/fetch_portal_sounds.sh`. |
| `sounds/synth/*.wav` | 864 KB | Procedurally synthesized replacement (`tools/generate_sounds.py`), freely redistributable |

**Done purely in QML** (no image, no shader): calibration ring, tick ring and crosshair (Shapes / Rectangles), all glows, the core, the portal flicker and the fog (radial vector gradients), grid, scanline sweep, vignette, color grading, panels, buttons, fields, HUD, boot terminal, glitch effect, flashes, and fades in and out.
All continuous animations only change `opacity`, `rotation`, `scale` or position. Nothing is redrawn or tessellated, and there is no canvas, particle system or video running.
Invisible elements stop their animations (e.g. the ring in standby). `reduceMotion=true` turns off everything continuous.

> **Note:** The background motif and `sounds/portal/` contain Valve/Portal material or are inspired by it. This is fan-project material, not covered by the GPL, and credited in the main README. To redistribute without it, remove `sounds/portal/` (or set `soundPack=synth`) and use your own background image.

## Known limitations

- **Sound in the real greeter:** SDDM runs as the `sddm` user, which, depending on the distribution, has no PipeWire/PulseAudio session. The theme then stays silent but otherwise works normally. In test mode (which runs as you) the sounds are audible.
- **Keyboard layout on Wayland:** If the greeter runs on KWin/Wayland, SDDM's `keyboard` model reports no layouts. The selector is then hidden, and the layout comes from the SDDM/KWin configuration.
- **"Unknown user" vs. "wrong password":** PAM and SDDM do not distinguish the two cases (only `loginFailed`), so the theme deliberately shows a single shared message.
- **4K sharpness of the background:** The image is 1672 px wide and is upscaled to 4K. Dimming and scanlines mask this; for maximum sharpness you can set a larger image via `background=` (then adjust or disable `sceneGlows`).
- **Software rendering** (VMs without a GPU): works, but `reduceMotion=true` is recommended for low CPU load.
- User avatars are not shown; selection is through the name list.

## What was tested

- `qmllint` (Qt 6.10) over all QML files: no errors. Only hints about SDDM context objects remain, which qmllint cannot know.
- `sddm-greeter-qt6 --test-mode` (SDDM 0.21, Qt 6.10): the theme and QtMultimedia load without QML warnings. A probe theme was used to check how SDDM provides `config`, `primaryScreen`, `keyboard`, `sddm`, `userModel` and `sessionModel`.
- Simulated flows with `tools/preview.py` and reviewed screenshots: boot, login, authentication, error with automatic reset, success with fade-out, standby and wake-up, power menu via keyboard, empty user.
- Resolutions: 1366×768, 1280×1024, 1920×1080, 2560×1440, 3440×1440, 3840×2160, `uiScale=1.5` (the console is fitted automatically), secondary screen, `language=en`, `reduceMotion`, `soundPack=synth`.
- **Not tested:** a real login through the SDDM daemon, real power actions, sound in the real greeter, real multi-monitor hardware.

## Aperture OS design tokens

Colors and fonts in `theme.conf` are generated from the Aperture OS tokens (`tools/build.py`,
in the main repo via `tools/build-all.sh`). Because SDDM runs as its own user and does not see the fonts in
`~/.local/share/fonts`, Inter, JetBrains Mono and Barlow Semi Condensed (SIL OFL) are in
`assets/fonts/` and are loaded in `Main.qml` with a `FontLoader`. The background is the upscaled
2560×1440 test chamber (glow positions scale automatically). The original Portal sounds are in
`sounds/portal/` (Valve-owned, see the note above).

After changes: `sudo ./install.sh` (the script replaces `/usr/share/sddm/themes/aperture-protocol` completely).
