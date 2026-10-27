// Slow dust motes rising through a region (source px).
import QtQuick

Item {
    id: dust
    required property var wp
    property real x0: 0
    property real x1: 100
    property real y0: 0              // top
    property real y1: 100            // bottom (particles rise from y1 to y0)
    property int count: 10
    property color color: "#5CCDF7"
    property real seed: 0
    property real alpha: 0.5

    Repeater {
        model: dust.count
        delegate: Rectangle {
            required property int index
            readonly property real r1: Math.abs((Math.sin((index + dust.seed) * 12.9898) * 43758.5453) % 1)
            readonly property real r2: Math.abs((Math.sin((index + dust.seed) * 78.233) * 12543.1234) % 1)
            readonly property real period: 26 + 22 * r2
            readonly property real phase: (dust.wp.t / period + r1) % 1
            width: Math.max(1.5, dust.wp.k * (1.2 + 1.6 * r2)); height: width
            radius: width / 2
            color: dust.color
            x: dust.wp.mapX((dust.x0 + (dust.x1 - dust.x0) * r1) / 1672
                            + 0.006 * Math.sin((dust.wp.t / (9 + 5 * r2) + r1) * 2 * Math.PI)) - width / 2
            y: dust.wp.mapY((dust.y1 - (dust.y1 - dust.y0) * phase) / 941) - height / 2
            opacity: dust.wp.intensity * dust.alpha * (0.5 + 0.7 * r2) * Math.sin(Math.PI * phase)
        }
    }
}
