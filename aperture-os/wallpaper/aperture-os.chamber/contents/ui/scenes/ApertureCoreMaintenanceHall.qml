// Core maintenance bay: big blue core breathes, the other cores pulse slower,
// neon tubes flicker now and then, dust drifts through the light shaft.
// Positions are in source-art pixels (1672x941), see ../Spot.qml.
import QtQuick
import ".."

Item {
    id: scene
    required property var wp

    Spot { wp: scene.wp; px: 860; py: 200; size: 340; color: "#00AEEF"; centre: 0.10; period: 18; lo: 0.4; hi: 1 }   // shaft haze

    // big core, upper right
    Spot { wp: scene.wp; px: 1205; py: 348; size: 330; color: "#00AEEF"; centre: 0.26; period: 5; lo: 0.25; hi: 0.85 }
    Spot { wp: scene.wp; px: 1205; py: 348; size: 100; color: "#5CCDF7"; centre: 0.8; period: 5; lo: 0.35; hi: 0.9 }
    // yellow + pink cores
    Spot { wp: scene.wp; px: 729; py: 432; size: 90; color: "#FFB300"; centre: 0.55; period: 7; phase: 0.3; lo: 0.3; hi: 0.9 }
    Spot { wp: scene.wp; px: 918; py: 545; size: 55; color: "#E040FB"; centre: 0.5; period: 9; phase: 0.6; lo: 0.25; hi: 0.9 }
    Spot { wp: scene.wp; px: 1318; py: 632; size: 50; color: "#00AEEF"; centre: 0.4; period: 8; phase: 0.2; lo: 0.3; hi: 0.9 }
    Spot { wp: scene.wp; px: 1368; py: 632; size: 50; color: "#FFD21F"; centre: 0.4; period: 11; phase: 0.7; lo: 0.3; hi: 0.9 }

    // tubes
    Tube { wp: scene.wp; px: 212; py: 38; len: 90; thick: 7; angle: 13; period: 13; flickerEvery: 31 }
    Tube { wp: scene.wp; px: 340; py: 545; len: 70; thick: 9; angle: 90; period: 9; phase: 0.3 }
    Tube { wp: scene.wp; px: 1440; py: 195; len: 50; thick: 6; angle: 90; period: 11; flickerEvery: 43; flickerOffset: 9 }
    Tube { wp: scene.wp; px: 1440; py: 425; len: 26; thick: 5; angle: 90; period: 8 }
    Tube { wp: scene.wp; px: 1640; py: 548; len: 36; thick: 5; angle: 0; period: 10; phase: 0.5 }
    Spot { wp: scene.wp; px: 120; py: 495; size: 230; color: "#00AEEF"; centre: 0.16; period: 6; lo: 0.4; hi: 1; flickerEvery: 27; flickerOffset: 5 }  // monitor

    Dust { wp: scene.wp; x0: 800; x1: 930; y0: 140; y1: 640; count: 12; seed: 3; alpha: 0.5 }
}
