# Contributing

## Layout and conventions
Every component is a self-contained folder. Required files, naming and token rules are in
[`docs/CONVENTIONS.md`](docs/CONVENTIONS.md). `design/tokens.json` is the single source for colours, radii, fonts.

## Build
```
tools/build-all.sh            # copy design/tokens.json into each component and regenerate everything
tools/build-all.sh --install  # then run ./install.sh (installs, activates nothing)
```
Needs Python 3 (standard library); Pillow only for `cursors`, `plymouth`, `wallpaper/tools`.

## Lint
```
tools/lint.sh   # JSON/XML/SVG parse, Python compile, bash -n + shellcheck, qmlformat syntax check
```
Run build and lint before every commit.

## Generated files
Generated output is committed so the repo installs without a build. Never edit it by hand: change
`design/tokens.json` or the component's `tools/build.py` and rebuild. Generated or copied files include
`*/tokens.json`, `ApertureTokens.qml`, compiled `.mo` (`tools/build-l10n.py`), the Kvantum/Kate/Plymouth/PhpStorm
outputs, `globaltheme/.../splash` (`globaltheme/tools/sync-splash.sh`) and `phpstorm/dist/*.jar`
(committed on purpose so `phpstorm/install.sh` works without a build; rebuild with `phpstorm/tools/build.py`).
CI rebuilds and fails if any committed text file changes.

## Releases
1. Bump `Version` in the package metadata, add a `## [X.Y.Z] – date` section to [`CHANGELOG.md`](CHANGELOG.md).
2. `git tag vX.Y.Z && git push origin vX.Y.Z`

CI then builds `dist/` (`tools/package-store.sh`) and publishes a GitLab release with the packages as assets.

## Third-party material
Add anything copied or derived to [`THIRD_PARTY.md`](THIRD_PARTY.md) with its licence and keep SPDX headers.

## Language
Code, comments, commit messages and docs are in English. The desktop UI itself is localised via `po/` catalogs (English source, German translation).
