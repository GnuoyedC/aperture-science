import QtQuick

// Segmented level bar (0..1): filled blocks like an industrial power gauge.
Item {
    id: bar

    property Tokens tk
    property real value: 0
    property int segments: 12
    property color color: tk ? tk.blue : "white"
    property int spacing: 2

    implicitHeight: 9
    implicitWidth: 120

    readonly property int filled: Math.round(Math.max(0, Math.min(1, value)) * segments)
    readonly property real segmentWidth: Math.max(2, (width - (segments - 1) * spacing) / segments)

    Repeater {
        model: bar.segments
        Rectangle {
            required property int index
            readonly property bool on: index < bar.filled
            x: Math.round(index * (bar.segmentWidth + bar.spacing))
            width: Math.round((index + 1) * (bar.segmentWidth + bar.spacing)) - x - bar.spacing
            height: bar.height
            radius: 1
            color: on ? bar.color : "transparent"
            opacity: on ? 0.92 : 1
            border.width: on ? 0 : 1
            border.color: bar.tk ? bar.tk.alpha(bar.tk.border, 0.9) : "gray"
        }
    }
}
