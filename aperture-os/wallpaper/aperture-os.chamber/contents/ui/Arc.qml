// Elliptic stroke (arc) centred in the item; a wide faint pass plus a thin core
// pass fake a soft glow without shaders.
import QtQuick
import QtQuick.Shapes

Shape {
    id: arc
    property color color: "#FF7800"
    property real start: 0
    property real sweep: 360
    property real lineWidth: 2
    property real haloWidth: 8
    property real haloAlpha: 0.18
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        fillColor: "transparent"
        strokeColor: Qt.rgba(arc.color.r, arc.color.g, arc.color.b, arc.haloAlpha)
        strokeWidth: arc.haloWidth
        capStyle: ShapePath.RoundCap
        PathAngleArc {
            centerX: arc.width / 2; centerY: arc.height / 2
            radiusX: arc.width / 2; radiusY: arc.height / 2
            startAngle: arc.start; sweepAngle: arc.sweep
        }
    }
    ShapePath {
        fillColor: "transparent"
        strokeColor: arc.color
        strokeWidth: arc.lineWidth
        capStyle: ShapePath.RoundCap
        PathAngleArc {
            centerX: arc.width / 2; centerY: arc.height / 2
            radiusX: arc.width / 2; radiusY: arc.height / 2
            startAngle: arc.start; sweepAngle: arc.sweep
        }
    }
}
