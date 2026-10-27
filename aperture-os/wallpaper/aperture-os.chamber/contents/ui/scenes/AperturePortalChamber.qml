// Test chamber with both portals: orange and blue portal shimmer, the blue LED
// lamps flash up one after the other from top to bottom, the red camera blinks,
// the water below glows.
import QtQuick
import ".."

Item {
    id: scene
    required property var wp
    PortalOverlays { id: ov }

    // portals: their own ring pixels breathe, plus a soft glow around them
    Spot { wp: scene.wp; px: 1138; py: 372; size: 260; color: "#FF7800"; centre: 0.32; period: 4.3; lo: 0.55; hi: 1 }
    Cutout {
        wp: scene.wp; r: ov.orange
        opacity: scene.wp.intensity * (0.35 + 0.65 * scene.wp.wave(2.3, 0.2))
    }
    Spot { wp: scene.wp; px: 847; py: 640; size: 220; color: "#00AEEF"; centre: 0.34; period: 5.1; phase: 0.4; lo: 0.55; hi: 1 }
    Cutout {
        wp: scene.wp; r: ov.blue
        opacity: scene.wp.intensity * (0.35 + 0.65 * scene.wp.wave(2.7, 0.5))
    }

    // blue LED strips: the lamps flash up one after the other from top to bottom,
    // then the strip rests (the two strips sweep at different times)
    LedStrip { wp: scene.wp; r: ov.led1; bands: ov.led1Bands; period: 7; offset: 1.0 }
    LedStrip { wp: scene.wp; r: ov.led2; bands: ov.led2Bands; period: 9; offset: 4.6; step: 0.07 }

    // ceiling lamp + water + orange platform lights
    Spot { wp: scene.wp; px: 860; py: 120; size: 300; color: "#00AEEF"; centre: 0.22; period: 9; lo: 0.4; hi: 1 }
    Spot { wp: scene.wp; px: 905; py: 826; size: 330; color: "#00AEEF"; centre: 0.22; period: 4; phase: 0.3; lo: 0.4; hi: 1 }
    Spot { wp: scene.wp; px: 1300; py: 512; size: 130; color: "#FF9A3D"; centre: 0.3; period: 8; lo: 0.4; hi: 1 }
    Spot { wp: scene.wp; px: 1395; py: 785; size: 220; color: "#FF9A3D"; centre: 0.16; period: 10; phase: 0.5; lo: 0.4; hi: 1 }
    Spot { wp: scene.wp; px: 127; py: 124; size: 46; color: "#FF3B30"; centre: 0.9; blinkEvery: 3.4; blinkOn: 0.4; hi: 1; lo: 0.6 }    // camera
    Spot { wp: scene.wp; px: 335; py: 755; size: 70; color: "#FF9A3D"; centre: 0.4; period: 9; lo: 0.4; hi: 1 }

    Dust { wp: scene.wp; x0: 700; x1: 1000; y0: 150; y1: 520; count: 12; seed: 2; alpha: 0.4 }
}
