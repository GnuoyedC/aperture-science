import QtQuick

// Static status LED: a small dot inside a thin ring (no animation, so nothing
// runs while the launcher is closed).
Item {
    id: led

    property Tokens tk
    property color color: tk ? tk.blue : "white"
    property real size: 7

    implicitWidth: size + 4
    implicitHeight: size + 4

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
    }
}
