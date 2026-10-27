// Research complex at night: moon and logo window breathe, red warning lights
// blink on the towers, windows glow warmly, fog drifts over the valley.
import QtQuick
import ".."

Item {
    id: scene
    required property var wp

    Spot { wp: scene.wp; px: 1268; py: 150; size: 190; color: "#BFD8FF"; centre: 0.28; period: 16; lo: 0.45; hi: 1 }       // moon
    Spot { wp: scene.wp; px: 742; py: 413; size: 230; color: "#BFD8FF"; centre: 0.3; period: 9; lo: 0.35; hi: 1 }          // logo window
    Spot { wp: scene.wp; px: 440; py: 420; size: 330; color: "#FF9A3D"; centre: 0.10; period: 12; phase: 0.2; lo: 0.4; hi: 1 }  // office windows
    Spot { wp: scene.wp; px: 910; py: 440; size: 220; color: "#FF9A3D"; centre: 0.09; period: 15; phase: 0.6; lo: 0.4; hi: 1 }
    Spot { wp: scene.wp; px: 1052; py: 330; size: 160; color: "#FFB35C"; centre: 0.14; period: 10; phase: 0.1; lo: 0.4; hi: 1 }  // tower windows
    Spot { wp: scene.wp; px: 62; py: 125; size: 110; color: "#FFD08A"; centre: 0.3; period: 14; lo: 0.5; hi: 1; flickerEvery: 37; flickerOffset: 4 }  // lamp
    Spot { wp: scene.wp; px: 1540; py: 590; size: 90; color: "#FF9A3D"; centre: 0.3; period: 7; lo: 0.4; hi: 1 }           // bridge hut

    // red warning lights, each with its own rhythm
    Spot { wp: scene.wp; px: 433; py: 238; size: 36; color: "#FF3B30"; centre: 0.8; blinkEvery: 2.6; blinkOn: 0.35; hi: 1; lo: 0.6 }
    Spot { wp: scene.wp; px: 1008; py: 127; size: 40; color: "#FF3B30"; centre: 0.8; blinkEvery: 3.1; blinkOn: 0.35; flickerOffset: 0.8; hi: 1; lo: 0.6 }
    Spot { wp: scene.wp; px: 1091; py: 136; size: 40; color: "#FF3B30"; centre: 0.8; blinkEvery: 3.1; blinkOn: 0.35; flickerOffset: 0.8; hi: 1; lo: 0.6 }
    Spot { wp: scene.wp; px: 1413; py: 430; size: 34; color: "#FF3B30"; centre: 0.8; blinkEvery: 4.4; blinkOn: 0.4; flickerOffset: 2; hi: 1; lo: 0.6 }
    Spot { wp: scene.wp; px: 1460; py: 158; size: 30; color: "#FF3B30"; centre: 0.7; blinkEvery: 3.7; blinkOn: 0.3; flickerOffset: 1.4; hi: 1; lo: 0.6 }

    // fog banks drifting slowly
    Spot { wp: scene.wp; px: 1300 + 70 * Math.sin(scene.wp.t / 150 * 2 * Math.PI); py: 760; size: 620; color: "#9FB8D8"; centre: 0.07; period: 0; hi: 1 }
    Spot { wp: scene.wp; px: 760 + 90 * Math.sin(scene.wp.t / 190 * 2 * Math.PI + 1); py: 640; size: 560; color: "#9FB8D8"; centre: 0.06; period: 0; hi: 1 }
    Dust { wp: scene.wp; x0: 1150; x1: 1350; y0: 600; y1: 840; count: 8; seed: 5; color: "#BFD8FF"; alpha: 0.4 }
}
