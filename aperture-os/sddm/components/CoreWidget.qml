import QtQuick

// Glowing "core" light. Used both for the robot eye in the background image
// and for the core behind the aperture emblem.
//
// mode: "idle" (slow blue breathing), "active" (brighter, faster),
//       "success" (bright white-blue flash), "error" (red)
Item {
    id: core

    property var theme
    property string mode: "idle"
    property bool animated: true
    property real size: 120

    width: size
    height: size

    readonly property color tint: mode === "error" ? theme.error
                                : mode === "success" ? theme.blueBright
                                : theme.blue

    // Outer halo.
    GlowBlob {
        id: halo
        anchors.centerIn: parent
        width: core.size
        height: core.size
        color: core.tint
        intensity: 0.55
        falloff: 0.3
        Behavior on color { ColorAnimation { duration: core.theme.normal } }
    }

    // Hot centre.
    GlowBlob {
        id: hot
        anchors.centerIn: parent
        width: core.size * 0.28
        height: core.size * 0.28
        color: core.mode === "success" ? "white" : Qt.lighter(core.tint, 1.35)
        intensity: 0.95
        falloff: 0.55
        Behavior on color { ColorAnimation { duration: core.theme.normal } }
    }

    // Slow "breathing". Uses opacity/scale only – no repaint needed.
    SequentialAnimation {
        running: core.animated && core.visible && core.mode !== "success"
        loops: Animation.Infinite
        alwaysRunToEnd: false
        ParallelAnimation {
            NumberAnimation { target: halo; property: "opacity"; to: 0.55; duration: core.mode === "error" ? 380 : 2600; easing.type: Easing.InOutSine }
            NumberAnimation { target: halo; property: "scale"; to: 0.92; duration: core.mode === "error" ? 380 : 2600; easing.type: Easing.InOutSine }
        }
        ParallelAnimation {
            NumberAnimation { target: halo; property: "opacity"; to: 1.0; duration: core.mode === "error" ? 380 : 2600; easing.type: Easing.InOutSine }
            NumberAnimation { target: halo; property: "scale"; to: 1.0; duration: core.mode === "error" ? 380 : 2600; easing.type: Easing.InOutSine }
        }
        onRunningChanged: if (!running) { halo.opacity = 1; halo.scale = 1 }
    }

    // Success: one short bright swell.
    SequentialAnimation {
        running: core.mode === "success"
        NumberAnimation { target: halo; property: "scale"; to: 1.45; duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation { target: halo; property: "scale"; to: 1.15; duration: 520; easing.type: Easing.InOutSine }
    }
}
