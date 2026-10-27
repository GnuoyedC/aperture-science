import QtQuick

// Thin continuous level bar (0..1) on a 1 px track with quarter ticks.
Item {
    id: bar

    property Tokens tk
    property real value: 0
    property color color: tk ? tk.blue : "white"

    implicitHeight: 6
    implicitWidth: 80

    Rectangle {
        id: track
        anchors.fill: parent
        color: bar.tk ? bar.tk.alpha(bar.tk.background, 0.55) : "black"
        border.width: 1
        border.color: bar.tk ? bar.tk.alpha(bar.tk.border, 0.9) : "gray"
        radius: bar.tk ? bar.tk.radiusControl / 2 : 1
    }
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 2
        width: Math.max(0, Math.min(1, bar.value)) * (bar.width - 4)
        color: bar.color
        opacity: 0.9
    }
    Repeater {
        model: 3
        Rectangle {
            required property int index
            x: Math.round((index + 1) * bar.width / 4)
            y: 0
            width: 1
            height: bar.height
            color: bar.tk ? bar.tk.alpha(bar.tk.background, 0.8) : "black"
        }
    }
}
