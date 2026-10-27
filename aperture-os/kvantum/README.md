# Aperture OS – Kvantum (transparent Dolphin)

Kvantum theme **ApertureOS**: tinted security glass for Dolphin.

* Window background 86 % opaque (`alpha.window`) with KWin blur, **text stays fully opaque**
* File view transparent (`transparent_dolphin_view`), context menus 94 % opaque
* flat (base: *KvFlat* from Kvantum, recolored to the Aperture tokens)
* Selection in lists/menus: dark orange tone + orange signal bar on the left (as in the Plasma Style),
  light text with ≥ 10:1 contrast – no glaring orange block

**Only Dolphin** uses Kvantum. All other applications stay on Breeze. This is done via an
entry in Dolphin's own configuration (KDE applications read the style from their `<app>rc` first):

```ini
# ~/.config/dolphinrc
[KDE]
widgetStyle=kvantum
```

This works for every way of launching (launcher, taskbar, "Show in Folder", session restore).
The same works for any other KDE application, e.g. `kwriteconfig6 --file katerc --group KDE --key widgetStyle kvantum`.

## Installation

```bash
sudo apt install qt6-style-kvantum   # once
./install.sh --activate              # install the theme + select it + switch Dolphin
./install.sh --global                # optional: Kvantum for ALL applications instead of Breeze
./install.sh --uninstall             # revert everything, Dolphin back to Breeze
```

Afterwards, close and reopen any running Dolphin windows.

## Customization

```bash
python3 tools/build.py   # reads tokens.json + /usr/share/Kvantum/KvFlat, writes ApertureOS/
./install.sh
```

Transparency: `alpha.window` (windows) and `alpha.menu` (menus) in `tokens.json`.
Fine-tuning: `GENERAL`, `COLORS`, `HACKS` and `SELECTION` at the top of `tools/build.py`, or graphically with
`kvantummanager` (changes made there are overwritten by the next build).
