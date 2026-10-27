// Glow at a position given in source-art pixels (1672x941): breathes with a sine,
// optionally flickers (short irregular dip) or blinks (short pulse).
import QtQuick

Glow {
    id: spot
    required property var wp
    property real px: 0
    property real py: 0
    property real size: 100          // diameter in source px
    property real period: 6          // breathing period in s (0 = steady at `hi`)
    property real phase: 0
    property real lo: 0.35           // opacity range * intensity
    property real hi: 1.0
    property real flickerEvery: 0    // s between flicker dips (0 = off)
    property real flickerOffset: 0
    property real blinkEvery: 0      // s between blinks (0 = off); blinks replace breathing
    property real blinkOn: 0.18
    property real boost: 1

    readonly property real cycle: flickerEvery > 0 ? (wp.t + flickerOffset) % flickerEvery : 0
    readonly property real flicker: flickerEvery > 0 && cycle < 0.6 ? 0.4 + 0.6 * Math.abs(Math.sin(cycle * 23)) : 1
    readonly property real blinkCycle: blinkEvery > 0 ? (wp.t + flickerOffset) % blinkEvery : 0
    readonly property real level: blinkEvery > 0
        ? (blinkCycle < blinkOn ? hi : lo * 0.15)
        : (period > 0 ? lo + (hi - lo) * wp.wave(period, phase) : hi)

    width: wp.k * size; height: width
    x: wp.mapX(px / 1672) - width / 2
    y: wp.mapY(py / 941) - height / 2
    opacity: Math.min(1, wp.intensity * boost * level * flicker)
}
