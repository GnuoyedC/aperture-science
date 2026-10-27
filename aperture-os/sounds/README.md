# Aperture OS – Sounds

System sounds for the Aperture OS desktop theme (KDE Plasma 6, Wayland, PipeWire), made up of two parts:

1. **Sound theme `aperture-os`** – a freedesktop sound theme (like *Ocean*) built from Portal 2 effects.
   Designed for 8 hours a day at a desk: short, quiet, no voice output. Frequent sounds
   (click, volume, chat) are < 300 ms and normalized to a peak of −20 … −22 dBFS.
2. **Session sounds** ("Powering up" / "Powering down") – turret voice clips on login and on
   logout/shutdown, driven by systemd user units.

> **Legal note.** All sounds in `aperture-os/stereo/` and `session/sounds/` come from *Portal 2*
> (© Valve Corporation). They are fan-project material, are not covered by the GPL, and are credited in the
> main README. The fetch script regenerates them reproducibly from the pinned source commit.

## Contents

| Path | Purpose |
|---|---|
| `aperture-os/index.theme` | Theme description, `Inherits=ocean,freedesktop` (missing events fall back to Ocean) |
| `aperture-os/stereo/*.oga` | 44 sounds, Ogg Vorbis 48 kHz stereo (generated, committed) |
| `tools/fetch_sounds.sh` | Regenerates all `.oga` files reproducibly (pinned commit, ffmpeg) |
| `session/systemd/` | `turret-sounds.service`, `turret-shutdown-watch.service` |
| `session/bin/turret-shutdown-watch` | Python helper (logind delay inhibitor) |
| `session/sounds/` | `deploy_2.wav` (login), `disabled_4.wav` (logout/shutdown) |
| `install.sh` | Installation / activation / uninstallation |
| `tokens.json` | Copy of the design tokens (convention; not used by the sounds) |

## Event mapping

Source: [`sourcesounds/portal2`](https://github.com/sourcesounds/portal2) @ `36edc8b8` (the same commit
as in `aperture-sddm`), paths relative to `sound/`. Length after trimming, level = peak value.

| Event | Source (Portal 2) | Length | Peak |
|---|---|---:|---:|
| **frequent – tiny & quiet** | | | |
| `button-pressed` | `ui/p2_editor_click.wav` | 70 ms | −22 dB |
| `button-pressed-modifier` | `ui/ui_coop_hud_focus_01.wav` | 90 ms | −22 dB |
| `audio-volume-change` | `ui/ui_coop_hud_focus_02.wav` | 120 ms | −20 dB |
| `bell` | `ui/menu_invalid.wav` | 160 ms | −18 dB |
| `bell-window-system` | `ui/hint.wav` | 200 ms | −20 dB |
| `message-new-instant` | `labs/ding_on.wav` | 190 ms | −10 dB |
| `message-sent-instant` | `ui/ui_coop_hud_unfocus_01.wav` | 240 ms | −20 dB |
| `message-contact-in` | `ui/ui_coop_hud_activate_01.wav` | 150 ms | −18 dB |
| `message-contact-out` | `ui/ui_coop_hud_deactivate_01.wav` | 280 ms | −18 dB |
| `message-highlight` | `ui/p2_store_ui_add_to_cart_01.wav` | 200 ms | −16 dB |
| **Dialogs / hints** | | | |
| `dialog-information` | `ui/beepclear.wav` | 400 ms | −16 dB |
| `dialog-question` | `ui/ui_coop_hud_click_02.wav` | 420 ms | −16 dB |
| `dialog-warning` | `buttons/og_test_chamber_neg_01.wav` | 600 ms | −17 dB |
| `dialog-warning-auth` (Polkit) | `plats/door_round_blue_lock_01.wav` | 550 ms | −16 dB |
| `dialog-error` | `buttons/button_synth_negative_01.wav` | 450 ms | −14 dB |
| `dialog-error-serious` | `weapons/portalgun/portal_invalid_surface_01.wav` | 600 ms | −14 dB |
| `dialog-error-critical` | `alarms/klaxon1.wav` | 900 ms | −14 dB |
| `message-attention` | `props/post_message_announcer_01.wav` | 900 ms | −16 dB |
| **Tasks / results** | | | |
| `completion-success` | `buttons/button_synth_positive_01.wav` | 700 ms | −14 dB |
| `completion-fail` | `buttons/button_synth_negative_02.wav` | 600 ms | −14 dB |
| `completion-partial` | `ui/ui_select_02.wav` | 450 ms | −18 dB |
| `completion-rotation` | `ui/p2_editor_correction_01.wav` | 450 ms | −18 dB |
| `outcome-success` | `buttons/og_test_chamber_pos_01.wav` | 1.2 s | −16 dB |
| `outcome-failure` | `weapons/portalgun/portal_fizzle_01.wav` | 800 ms | −14 dB |
| `trash-empty` | `props/material_emancipation_01.wav` (emancipation grill) | 1.3 s | −16 dB |
| `complete-media-burn` | `labs/door_open_chime_01.wav` | 1.6 s | −16 dB |
| `complete-media-error` | `buttons/button_synth_negative_02.wav` | 1.0 s | −14 dB |
| `game-over-winner` | `buttons/og_test_chamber_pos_01.wav` | 2.2 s | −16 dB |
| `game-over-loser` | `weapons/portalgun/portal_fizzle_01.wav` | 1.5 s | −14 dB |
| **Hardware / power** | | | |
| `device-added` | `ui/p2_editor_konnektshun_made_01.wav` | 600 ms | −14 dB |
| `device-removed` | `ui/p2_editor_konnektshun_destroyed_01.wav` | 600 ms | −14 dB |
| `power-plug` | `ui/nv_powerup.wav` | 600 ms | −16 dB |
| `power-unplug` | `common/wpn_hudoff.wav` | 230 ms | −16 dB |
| `media-insert-request` | `plats/door_round_blue_unlock_01.wav` | 700 ms | −16 dB |
| `battery-full` | `labs/door_open_chime_01.wav` | 1.2 s | −18 dB |
| `battery-low` | `ui/p2_editor_error.wav` | 350 ms | −14 dB |
| `battery-caution` | `alarms/klaxon1.wav` | 600 ms | −16 dB |
| **Session / services / alarms (rare)** | | | |
| `desktop-login` | `weapons/portalgun/portalgun_powerup1.wav` | 1.3 s | −16 dB |
| `desktop-logout` | `weapons/portalgun_powerdown.wav` | 1.4 s | −14 dB |
| `service-login` | `weapons/portalgun/portal_open_blue_01.wav` | 750 ms | −16 dB |
| `service-logout` | `weapons/portalgun/portal_close1.wav` | 340 ms | −16 dB |
| `alarm-clock-elapsed` | `props/relaxing_alarm_clock_lp_01.wav` | 2.4 s | −12 dB |
| `phone-incoming-call` | `ui/beep22.wav` | 860 ms | −12 dB |
| `theme-demo` (preview in the KCM) | `props/pre_message_announcer_01.wav` (announcement chime) | 1.5 s | −14 dB |

All other event names are resolved through `Inherits=ocean,freedesktop`.

In Plasma, `desktop-login`/`desktop-logout` have **no** action by default (Notifications →
"Plasma Workspace" → Login/Logout). Leave it that way – login/logout are handled by the
turret session sounds (see below), otherwise you would get doubled sounds.

## Installation

```bash
./install.sh                # theme to ~/.local/share/sounds/aperture-os + session sounds; activates nothing
./install.sh --activate     # additionally set it as the system sound theme
./install.sh --no-session   # sound theme only
./install.sh --session-only # session sounds only
```

`install.sh` is idempotent. Requires: `bash`, `kwriteconfig6`/`kreadconfig6` (only for activation),
`systemctl --user`, `pw-play` and `python3-gi` (session sounds).

## Activation

Plasma 6 stores the system sound theme in **`~/.config/kdeglobals`, group `[Sound]`, key
`Theme`** (default `ocean`). This is the same value written by *System Settings → Colors & Themes →
System Sounds* (KCM `kcm_soundtheme`) and read by KNotifications (libcanberra).

`./install.sh --activate` backs up the previous value to `~/.local/state/aperture-os/sound-theme.prev`
(an empty file = the key was not set) and then sets:

```bash
kwriteconfig6 --file kdeglobals --group Sound --key Theme aperture-os
```

Alternatively, select "Aperture OS" in System Settings. Programs that are already running may only pick up
the theme after you log in again. GTK programs (libcanberra-gtk) use `gtk-sound-theme-name`
independently – this is deliberately left unchanged here.

Test without activating:

```bash
pw-play ~/.local/share/sounds/aperture-os/stereo/theme-demo.oga
canberra-gtk-play -i dialog-warning --property=canberra.xdg-theme.name=aperture-os   # if installed
```

## Session sounds ("Powering up" / "Powering down")

Turret voice clips from Portal 2 (`npc/turret_floor/turret_deploy_2.wav`, `turret_disabled_4.wav`,
edited: mono, 1 s of silence at the start so an HDMI output that is waking up does not cut anything off).
The files are made by hand and are **not** produced by the fetch script.

| File (installed to) | Function |
|---|---|
| `turret-sounds.service` → `~/.config/systemd/user/` | Part of `graphical-session.target`. **Start:** wait 3 s, then play `deploy_2.wav` with `pw-play --volume 0.4`. **Stop** (end of session): `disabled_4.wav`. Because systemd stops units in reverse order, KWin (and with it the HDMI signal) waits until the sound has finished (`TimeoutStopSec=8`). |
| `turret-shutdown-watch.service` → `~/.config/systemd/user/` | Runs under `default.target` (not tied to the graphical session) and starts the helper. |
| `turret-shutdown-watch` → `~/.local/bin/` | Holds a logind **delay inhibitor** for `shutdown`. On `PrepareForShutdown` it waits until `turret-sounds.service` has played its stop sound, then releases the lock. If the machine was shut down without a Plasma logout (e.g. `systemctl poweroff`), it plays `disabled_4.wav` itself. If a shutdown is cancelled, the lock is taken again. It also holds a **sleep** inhibitor: on `PrepareForSleep` it plays `still_there.wav` ("Are you still there?") before the machine goes into standby/hibernation, and re-takes the lock after waking up. |
| `deploy_2.wav`, `disabled_4.wav`, `still_there.wav` → `~/.local/share/turret-sounds/` | The sounds (`still_there.wav` = the German `turret_search_1`, standby) |

The units use `%h`, so the target paths are fixed. `install.sh` only copies changed files,
runs `systemctl --user daemon-reload`, and calls `enable` only if a unit is not yet
enabled. Running units are **never** started, stopped or restarted – stopping
`turret-sounds.service` would immediately play the shutdown sound. Changed units take effect from the next
login.

To change the volume: adjust `--volume 0.4` in `session/systemd/turret-sounds.service` (2×) **and** `VOLUME` in
`session/bin/turret-shutdown-watch`, then run `./install.sh --session-only`.

## Uninstallation

```bash
./install.sh --uninstall              # theme + session sounds
./install.sh --uninstall --no-session # theme only
```

- **Theme:** restores the backed-up `[Sound] Theme` value (or removes the key if none was set
  before – only if `aperture-os` is still the active theme) and deletes
  `~/.local/share/sounds/aperture-os`.
- **Session:** `systemctl --user disable` for both units, stops only the (silent) watcher, deletes the
  units, the helper and the two WAVs, then `daemon-reload`. `turret-sounds.service` is deliberately not
  stopped and ends with the running session (the stop sound is then missing because the file is gone).

## Replacing a sound

1. In `tools/fetch_sounds.sh`, change the event's `make` line:
   `make <event> <path under sound/> <start s> <length s> <fade-out s> <peak dBFS>`.
   Available files: `curl -s "https://api.github.com/repos/sourcesounds/portal2/git/trees/36edc8b85c4b5718289f56d8c3652a6dc0e58a1b?recursive=1"`.
   New event names (freedesktop sound naming spec) are simply added as a new line.
2. Run `tools/fetch_sounds.sh` (`--keep-raw` keeps the originals for listening), and check the result with
   `pw-play aperture-os/stereo/<event>.oga`.
3. Run `./install.sh --no-session`, update the table above, commit.

To use your own file instead of a Portal source: put it in as `aperture-os/stereo/<event>.oga` (Ogg Vorbis) and remove the
`make` line, otherwise it will be overwritten on the next fetch (the script empties `stereo/`).
