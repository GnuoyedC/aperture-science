# Aperture OS – Kate / KWrite

Editor color scheme **Aperture OS** for all KTextEditor applications (Kate, KWrite, KDevelop, Kile …),
as a KSyntaxHighlighting theme. The same syntax palette as the PhpStorm scheme – code looks identical in both
editors:

| Element | Color |
|---|---|
| Keywords, control flow | Orange (bold) |
| Types, functions | Blue / cyan |
| Strings | Green |
| Numbers, constants | Amber |
| Comments | Gray, italic |
| Selection | muted orange tone |
| Error / warning | Red / amber |

Background `surface` (#0D151C), every syntax color ≥ 4.5:1 contrast (checked during the build).
Kate's application UI comes from the KDE color scheme *Aperture OS*.

## Installation

```bash
./install.sh --activate   # to ~/.local/share/org.kde.syntax-highlighting/themes, select in Kate + KWrite
./install.sh --uninstall
```

Manually: Kate → Settings → Configure Kate → Color Themes → *Aperture OS*.
A running Kate picks up the theme after a restart.

## Customization

`python3 tools/build.py` (reads `tokens.json`, writes `aperture-os.theme`).
