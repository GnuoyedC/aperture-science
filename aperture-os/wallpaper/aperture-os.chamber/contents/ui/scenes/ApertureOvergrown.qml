// Overgrown chamber: the orange core pulses, the amber tubes on the right flicker,
// the distant portal shimmers, mist rises at the waterfall.
import QtQuick
import ".."

Item {
    id: scene
    required property var wp

    Spot { wp: scene.wp; px: 1108; py: 278; size: 340; color: "#FF7800"; centre: 0.26; period: 4.6; lo: 0.25; hi: 0.85 }
    Spot { wp: scene.wp; px: 1108; py: 278; size: 100; color: "#FFB35C"; centre: 0.8; period: 4.6; lo: 0.35; hi: 0.9 }

    // amber tubes on the right tower
    Tube { wp: scene.wp; px: 1108; py: 470; len: 105; thick: 6; angle: 90; period: 10; flickerEvery: 33 }
    Tube { wp: scene.wp; px: 1187; py: 518; len: 62; thick: 6; angle: 90; period: 12; phase: 0.3; flickerEvery: 47; flickerOffset: 11 }
    Tube { wp: scene.wp; px: 1335; py: 440; len: 52; thick: 6; angle: 90; period: 9; phase: 0.6 }
    Tube { wp: scene.wp; px: 1252; py: 688; len: 40; thick: 6; angle: 90; period: 11; phase: 0.1 }
    Tube { wp: scene.wp; px: 1190; py: 800; len: 60; thick: 6; angle: 90; period: 8; phase: 0.8; flickerEvery: 39; flickerOffset: 20 }
    Tube { wp: scene.wp; px: 440; py: 566; len: 100; thick: 6; angle: 4; period: 14; phase: 0.2 }
    Tube { wp: scene.wp; px: 125; py: 38; len: 70; thick: 6; angle: 8; period: 13; flickerEvery: 29; flickerOffset: 3 }
    Spot { wp: scene.wp; px: 1330; py: 480; size: 480; color: "#FF9A3D"; centre: 0.07; period: 16; lo: 0.4; hi: 1 }          // warm light of the tower

    // distant portal + left monitor
    Spot { wp: scene.wp; px: 757; py: 495; size: 110; color: "#FF7800"; centre: 0.4; period: 4.3; lo: 0.5; hi: 1 }
    Spot { wp: scene.wp; px: 130; py: 370; size: 260; color: "#00AEEF"; centre: 0.16; period: 6; lo: 0.4; hi: 1; flickerEvery: 23; flickerOffset: 6 }

    // waterfall mist + light shaft
    Spot { wp: scene.wp; px: 1000 + 25 * Math.sin(scene.wp.t / 70 * 2 * Math.PI); py: 700; size: 340; color: "#BFD8FF"; centre: 0.09; period: 0; hi: 1 }
    Spot { wp: scene.wp; px: 800; py: 250; size: 420; color: "#8FB8E8"; centre: 0.08; period: 22; lo: 0.4; hi: 1 }
    Dust { wp: scene.wp; x0: 880; x1: 1100; y0: 220; y1: 780; count: 14; seed: 4; color: "#BFD8FF"; alpha: 0.45 }
}
