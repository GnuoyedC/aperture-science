import QtQuick
import QtQuick.Shapes

// Two-series sparkline (download filled, upload as thin line) on a faint
// technical grid. Geometry is rebuilt only when a new sample arrives.
Item {
    id: spark

    property Tokens tk
    property var primary: []
    property var secondary: []
    property int capacity: 60
    property real peak: 0
    // Minimum full-scale value so idle traffic does not fill the chart.
    property real floor: 8000

    readonly property real fullScale: Math.max(peak * 1.15, floor)
    readonly property real step: width / Math.max(1, capacity - 1)

    function points(values, closed) {
        const pts = []
        const n = values.length
        const h = height - 1
        for (let i = 0; i < n; ++i) {
            const x = width - (n - 1 - i) * step
            const y = h - Math.min(1, values[i] / fullScale) * (h - 1)
            pts.push(Qt.point(x, y))
        }
        if (closed && n > 0) {
            pts.push(Qt.point(width, h))
            pts.push(Qt.point(width - (n - 1) * step, h))
        }
        return pts
    }

    // frame + grid
    Rectangle {
        anchors.fill: parent
        color: spark.tk.alpha(spark.tk.background, 0.45)
        border.width: 1
        border.color: spark.tk.alpha(spark.tk.border, 0.7)
    }
    Repeater {
        model: 3
        Rectangle {
            required property int index
            x: 1
            width: spark.width - 2
            y: Math.round((index + 1) * spark.height / 4)
            height: 1
            color: spark.tk.alpha(spark.tk.border, 0.35)
        }
    }
    Repeater {
        model: 5
        Rectangle {
            required property int index
            y: 1
            height: spark.height - 2
            x: Math.round((index + 1) * spark.width / 6)
            width: 1
            color: spark.tk.alpha(spark.tk.border, 0.25)
        }
    }

    Shape {
        anchors.fill: parent
        anchors.margins: 1
        preferredRendererType: Shape.CurveRenderer
        visible: spark.primary.length > 1

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillColor: spark.tk.alpha(spark.tk.blue, 0.14)
            PathPolyline { path: spark.points(spark.primary, true) }
        }
        ShapePath {
            strokeWidth: 1
            strokeColor: spark.tk.alpha(spark.tk.textMuted, 0.85)
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: spark.points(spark.secondary, false) }
        }
        ShapePath {
            strokeWidth: 1.2
            strokeColor: spark.tk.blue
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: spark.points(spark.primary, false) }
        }
    }
}
