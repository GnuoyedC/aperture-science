// Atrium with the hanging core: the core breathes, the logo window and the
// small portal glow, wall tubes flicker, dust drifts through the light beams.
import QtQuick
import ".."

Item {
    id: scene
    required property var wp

    Spot { wp: scene.wp; px: 858; py: 206; size: 330; color: "#00AEEF"; centre: 0.26; period: 5; lo: 0.25; hi: 0.85 }
    Spot { wp: scene.wp; px: 858; py: 206; size: 95; color: "#5CCDF7"; centre: 0.8; period: 5; lo: 0.35; hi: 0.9 }
    Spot { wp: scene.wp; px: 845; py: 508; size: 170; color: "#8FD8FF"; centre: 0.3; period: 10; phase: 0.3; lo: 0.3; hi: 1 }     // logo window
    Spot { wp: scene.wp; px: 850; py: 420; size: 520; color: "#00AEEF"; centre: 0.08; period: 20; lo: 0.4; hi: 1 }              // atrium haze
    Spot { wp: scene.wp; px: 1503; py: 525; size: 120; color: "#FF7800"; centre: 0.4; period: 4.3; lo: 0.5; hi: 1 }           // small portal

    Tube { wp: scene.wp; px: 38; py: 320; len: 170; thick: 9; angle: 90; period: 12; flickerEvery: 41; flickerOffset: 7 }
    Tube { wp: scene.wp; px: 478; py: 592; len: 62; thick: 7; angle: 90; period: 9; phase: 0.4 }
    Spot { wp: scene.wp; px: 1420; py: 700; size: 130; color: "#FF9A3D"; centre: 0.2; period: 8; lo: 0.4; hi: 1 }               // floor lights
    Spot { wp: scene.wp; px: 1235; py: 700; size: 110; color: "#FF9A3D"; centre: 0.2; period: 8; phase: 0.5; lo: 0.4; hi: 1 }

    Dust { wp: scene.wp; x0: 700; x1: 1000; y0: 280; y1: 720; count: 14; seed: 1; alpha: 0.5 }
}
