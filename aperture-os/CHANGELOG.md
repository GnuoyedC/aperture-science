# Changelog

All notable changes to Aperture OS are listed here. Versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- **Starship**: inside a ddev project the prompt shows the container's PHP version (`php_version` from
  `.ddev/config.yaml`) instead of the host `php`; the `ddev` tag is also shown in subdirectories of the project

## [1.0.0] – 2026-10-12

First public release of the Aperture OS design system for KDE Plasma 6.

### Components
- **Colour scheme** `ApertureOS`, **Plasma style** and **window decoration** (Aurorae), all generated from `design/tokens.json`
- **Global theme** (Look-and-Feel) with an optional panel layout – your panels and widgets are kept
- **Splash screen** "INITIALIZING APERTURE OS" and **lock screen** "Aperture Security System"
- **Launcher** `aperture-os.launcher` (replaces Kickoff on the Meta key)
- **Widgets**: Test Chamber, System Monitor, Aperture Notice
- **Wallpapers**: six test chamber motifs plus the animated wallpaper plugin `aperture-os.chamber`
- **Aperture cursors** – the recommended cursor theme (opt-in)
- **Sounds**: system sound theme and turret login/shutdown voice lines
- **SDDM** login screen "Aperture Protocol" and **Plymouth** boot screen
- **Kvantum** theme for a translucent Dolphin, **Kate** and **PhpStorm** colour schemes, terminal **dotfiles**
- **Guard**: tests the lock/logout screen after Plasma updates and disables it automatically on failure

### Packages
Every release ships one store package per component (installable via `kpackagetool6 -i` or
System Settings → "Get New …"), built by `tools/package-store.sh`.
