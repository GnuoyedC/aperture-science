// Lit tube / neon strip (soft capsule) at a position in source px: wide faint
// pass + thin bright core. angle in degrees (0 = horizontal, 90 = vertical).
import QtQuick

Item {
    id: tube
    required property var wp
    property real px: 0
    property real py: 0
    property real len: 60            // source px
    property real thick: 5
    property real angle: 90
    property color color: "#FF9A3D"
    property real period: 7
    property real phase: 0
    property real lo: 0.35
    property real hi: 1.0
    property real flickerEvery: 0
    property real flickerOffset: 0

    readonly property real cycle: flickerEvery > 0 ? (wp.t + flickerOffset) % flickerEvery : 0
    readonly property real flicker: flickerEvery > 0 && cycle < 0.5
        ? (cycle < 0.15 || (cycle > 0.25 && cycle < 0.4) ? 0.3 : 1) : 1

    width: wp.k * len; height: wp.k * thick
    x: wp.mapX(px / 1672) - width / 2
    y: wp.mapY(py / 941) - height / 2
    rotation: wp.mirror ? -angle : angle
    opacity: Math.min(1, wp.intensity * (lo + (hi - lo) * wp.wave(period, phase)) * flicker)

    Rectangle {   // halo
        anchors.centerIn: parent
        width: parent.width + tube.height * 4; height: tube.height * 4
        radius: height / 2
        color: Qt.rgba(tube.color.r, tube.color.g, tube.color.b, 0.16)
    }
    Rectangle {   // core
        anchors.centerIn: parent
        width: parent.width; height: Math.max(1.5, tube.height * 0.55)
        radius: height / 2
        color: Qt.rgba(tube.color.r, tube.color.g, tube.color.b, 0.55)
    }
}
