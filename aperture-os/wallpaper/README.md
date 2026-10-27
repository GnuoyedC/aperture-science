# Aperture OS – Wallpaper

## 1. Test chamber (default, static)

Image wallpaper package `ApertureTestChamber` in 1920×1080, 2560×1440 and 3840×2160. Upscaled from the
1672×941 original with Real-ESRGAN (`realesrgan-x4plus`, ncnn/Vulkan), blended with 20 % Lanczos and given a fine
grain – sharp edges/lettering, natural concrete texture, no banding.
Plasma automatically picks the matching size. It is also set as the lock screen background.

## 2. Animated test chamber (optional)

Wallpaper plugin `aperture-os.chamber` – the photo provides the atmosphere, and three soft vector lights add
a little life:

* the robot core "breathes" (blue, ~5 s)
* a light runs once around the cylinder's orange ring (~10 s, it dips out of sight at the back)
* the light cone under the core slowly swells and fades, with a very rare brief neon flicker
* the lit door behind the Companion Cube breathes with a time offset, and now and then the tubes flicker briefly
* the portal rim shimmers slightly (orange)
* a few dust particles rise through the light cone
* a large cold light field drifts slowly (~2 min)

Ring, light cone and door are not shapes painted on top: `tools/make_overlays.py` (Pillow) cuts the
glowing pixels out of the photo (ring in 15° segments), brightens them and adds a soft halo.
The plugin only changes their opacity. Medium strength, adjustable with *Intensity*. No shaders, no videos;
one timer at 10 updates/s (measured: about 2.8 % CPU). Settings: right-click → Configure Desktop and Wallpaper
(animation off, intensity, updates/s, mirror, zoom + image section, custom image).

**Image section per screen:** *Mirror* flips the scene horizontally (note: the lettering too),
*Zoom* (1–2) with *section left↔right / top↕bottom* picks a different section, e.g. core + portal.
All effects move with it. Per screen on the command line:
`./install.sh --frame <screen> <zoom> <x> <y> [mirror]`, `./install.sh --laptop` = logo + cube (zoom 1.25, left) on screen 1.

## Installation

```bash
./install.sh              # install both
./install.sh --activate   # test chamber (static) on all desktops + lock screen
./install.sh --animated   # animated plugin on all desktops
./install.sh --toggle     # animation on/off (the animated plugin stays set)
./install.sh --static     # back to the static image
./install.sh --uninstall
```

## Alternative motifs (static + animated)

Five more image packages, selectable via *Configure Desktop and Wallpaper*: `ApertureCoreMaintenanceHall`,
`ApertureResearchComplex`, `ApertureLaboratories`, `AperturePortalChamber`, `ApertureOvergrown`
(each 1920×1080, 2560×1440, 3840×2160). The sources are in `Images/`; generated with `tools/make_alternatives.py`
(Lanczos + light sharpening + fine grain, no AI upscaling).

The animated plugin knows the same motifs (*Motif* setting, or `./install.sh --animated <motif>` with
`core|research|laboratories|portals|overgrown`). Each motif has its own effect scene in
`aperture-os.chamber/contents/ui/scenes/`, using the same technique as above (timer, only opacity/position):

| Motif | Effects |
|---|---|
| Core maintenance hall | big core breathes, yellow/pink cores pulse more slowly, neon tubes flicker, dust in the light shaft |
| Research complex | moon + logo window breathe, red warning lights blink each at its own rhythm, window light, fog banks drift |
| Laboratories | core breathes, logo window + small portal glow, wall tubes flicker, dust in the light beams |
| Test chamber with portals | orange + blue portal shimmer (real ring pixels from the photo), blue LED lamps flash briefly, camera blinks, water glimmers |
| Overgrown test chamber | orange core pulses, amber tubes flicker, distant portal, fog at the waterfall |

The scenes assemble building blocks (`Spot`, `Tube`, `Dust`, `Cutout`, `Glow`, `Arc`); positions are given in
pixels of the 1672×941 original. The image packages must be installed (`./install.sh`); the plugin loads the image
from `~/.local/share/wallpapers/<package>/`. With a custom image (*Custom image*) the scene effects are off.

## Assignment per screen / lock screen

```bash
./install.sh --setup                   # main screen: test chamber · laptop (screen 1): test chamber with portals · lock screen: laboratories
./install.sh --lockscreen research    # change only the lock screen background
```

`--setup` sets the animated plugin with the screen's motif on every desktop (zoom/section/mirror
are reset in the process). The laptop screen is set at the top of the script (`LAPTOP_SCREEN`). SDDM
(`sddm/theme.conf`: research complex) and the splash screen (`splash/`, `globaltheme/`: core maintenance hall) have their own images.

## More test chambers

Copy the `ApertureTestChamber` folder, adjust `metadata.json` (id/name), and put images in `contents/images/` as `<W>x<H>.jpg`.
The glows of the animated plugin are tuned to the bundled motifs
(default image: `contents/ui/main.qml`, the others: `contents/ui/scenes/`) and are hidden automatically for custom images.

⚠️ The test chamber motif contains Aperture branding – Valve-owned fan-project material, not covered by the GPL, and credited in the main README.
