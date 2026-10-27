# Aperture OS – Roadmap

Ideas for later. None of these have been started. New components follow [`CONVENTIONS.md`](CONVENTIONS.md).

## Planned

| Topic | Idea | Notes |
|---|---|---|
| **More test chambers** | additional wallpaper motifs (chamber 02, 03 …) for `aperture-os.chamber` | Copy the wallpaper package and generate the effects from the photo pixels with `wallpaper/tools/make_overlays.py`. No painted-on shapes |
| **i18n for the wallpaper config** | translate the settings dialog of `aperture-os.chamber` | Domain `plasma_wallpaper_aperture-os.chamber`. `tools/build-l10n.py` currently only knows `plasma_applet_*` |

## Maybe

| Topic | Idea |
|---|---|
| GLaDOS messages | additional texts/sounds for the Notice widget |
| Plymouth HiDPI | also render the iris and texts at double size, in case Plymouth picks scale 2 on a display |
| Splitting out components | individual folders as their own repos via `git subtree split` (see README) |

## Deliberately not planned

Replacing icons or activating the cursor automatically (both stay opt-in), wobbly windows / magic lamp, custom KWin scripts,
a notification fork for per-urgency colors.
