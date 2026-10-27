import QtQuick

// Status LED: a small dot inside a thin ring. Optional slow "breathing".
// The breathing is stepped by a timer (~8 fps) instead of a continuous
// animation, so the shell is not forced to repaint at display refresh rate.
Item {
    id: led

    property Tokens tk
    property color color: tk ? tk.blue : "white"
    property bool breathing: false
    property bool reduceMotion: false
    property int period: tk ? tk.motionPulse : 4000
    property real size: 7

    implicitWidth: size + 4
    implicitHeight: size + 4

    property real phase: 0
    readonly property bool animating: breathing && !reduceMotion && visible

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(led.color.r, led.color.g, led.color.b, 0.35)
    }
    Rectangle {
        anchors.centerIn: parent
        width: led.size - 2
        height: width
        radius: width / 2
        color: led.color
        opacity: led.animating ? 0.45 + 0.55 * (0.5 + 0.5 * Math.cos(led.phase * 2 * Math.PI)) : 1
    }
    Timer {
        interval: 125
        repeat: true
        running: led.animating
        onTriggered: led.phase = (led.phase + interval / led.period) % 1
        onRunningChanged: if (!running) led.phase = 0
    }
}
