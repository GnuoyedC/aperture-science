# Aperture OS – Lock screen "Aperture Security System"

```text
◉ APERTURE SECURITY SYSTEM                                   14:37
  APERTURE OS · TEST CHAMBER 01                  SUNDAY, OCTOBER 4

                 ┌ ◉ TEST SUBJECT      [ AUTHENTICATION ] ┐
                 │              (Avatar)                  │
                 │              Subject                   │
                 │      [ Password            ] [>]       │
                 └ Standby   Switch User                  ┘

                  ● STATUS: LOCKED · SUBJECT 001
```

* slightly transparent login panel with orange corner brackets, cyan status LED (breathes slowly)
* Failed attempt: brief red glitch, red border, `STATUS: ACCESS DENIED`
* The entire authentication logic is taken **unchanged** from the Plasma 6.6 lock screen
  (password, fingerprint, smartcard, virtual keyboard, media, standby, user switching).
  Changes are marked "Aperture OS" in `LockScreenUi.qml`; `ApertureHud.qml` is new.

## Important: how Plasma 6.6 loads the lock screen

Since Plasma 6, the lock screen belongs to the **shell package**, no longer to the Global Theme. The greeter
reads `plasmashellrc [Shell] ShellPackage` – the same key as plasmashell itself.
This repo therefore ships the shell package `aperture-os.shell`, which contains *only* `contents/lockscreen`
and falls back to `org.kde.plasma.desktop` for everything else via `X-Plasma-FallbackPackage`.

Because plasmashell derives the name of its panel configuration from the shell name
(`plasma-<shell>-appletsrc`), `--activate` creates `plasma-aperture-os.shell-appletsrc` as a **symlink** to
`plasma-org.kde.plasma.desktop-appletsrc`. KConfig follows symlinks when saving – so both names always share
the same file, panels and widgets cannot drift apart, and tools that expect the
default name keep working.

## Installation

```bash
./install.sh                     # install the package – changes nothing on the active system
./install.sh --preview           # 20 s preview in test mode (moving the mouse shows the login field)
./install.sh --activate --now    # activate and restart plasmashell immediately (otherwise: log in again)
./install.sh --deactivate --now  # back to the default shell
./install.sh --uninstall
```

**Status:** active on the work system (Plasma 6.6.6): panels/widgets complete after a plasmashell restart,
the greeter loads the Aperture package via `plasmashellrc [Shell] ShellPackage`.
Emergency (e.g. after a Plasma update, if the lock screen reports "broken"):
in a TTY (Ctrl+Alt+F3) run `loginctl unlock-session` and then `./install.sh --deactivate --now`.

Without activation, the Breeze lock screen shows the Aperture colors and the test chamber background.

## Customization

`ApertureHud.qml` (texts, layout), `ApertureTokens.qml` (from `tokens.json`, `python3 tools/build.py`).
After a Plasma update, compare the stock files from `/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen`
with this copy and carry over the "Aperture OS" sections.
