# Aperture Dark for Firefox

Built to match the Aperture-Dark icon theme. It has two parts; use either one or both.

## 1. The theme (`dist/aperture-dark-firefox.xpi`)

This colours the tabs, toolbar, URL bar, menus, sidebar and New Tab page. It also puts a faint aperture and ring-light graphic in the tab strip.

Release builds of Firefox only install permanently if the add-on has been signed by Mozilla. Signing is free and automatic for themes:

1. Go to <https://addons.mozilla.org/developers/addon/submit/distribution> and sign in.
2. Choose **On your own** (unlisted, so it isn't published).
3. Upload `aperture-dark-firefox.xpi`.
4. Download the signed file it gives back, then drag it onto a Firefox window.

To try it without signing, open `about:debugging#/runtime/this-firefox`, click **Load Temporary Add-on…** and pick the `.xpi`. It stays loaded until Firefox restarts.

## 2. HUD styling (`chrome/`, optional)

This goes beyond what a theme is allowed to change:
- the selected tab gets a teal frame and an amber light strip;
- the focused URL bar glows blue;
- menu items get an amber marker;
- the New Tab page gets a full Aperture HUD backdrop.

Close Firefox, then run:

```sh
./install-chrome.sh              # finds regular, Flatpak and Snap profiles
./install-chrome.sh --uninstall
```

The script copies the files into each profile's `chrome/` folder. It also enables `toolkit.legacyUserProfileCustomizations.stylesheets` through that profile's `user.js`. Any existing `userChrome.css`/`userContent.css` is backed up first as `*.before-aperture`.

These stylesheets use Firefox's internal element names. A future Firefox update can break part of them; if it does, the rest of the theme still works.

## Rebuild

```sh
python3 firefox/build_firefox.py
```
Colours come from the icon theme's palette in `build_dark.py`.
