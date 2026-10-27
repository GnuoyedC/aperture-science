// Soft radial glow (ellipse with a radial alpha falloff); no shaders.
import QtQuick
import QtQuick.Shapes

Shape {
    id: glow
    property color color: "#00AEEF"
    property real centre: 0.5
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeWidth: -1
        strokeColor: "transparent"
        fillGradient: RadialGradient {
            centerX: glow.width / 2; centerY: glow.height / 2
            focalX: centerX; focalY: centerY
            centerRadius: Math.min(glow.width, glow.height) / 2
            focalRadius: 0
            GradientStop { position: 0.0; color: Qt.rgba(glow.color.r, glow.color.g, glow.color.b, glow.centre) }
            GradientStop { position: 0.4; color: Qt.rgba(glow.color.r, glow.color.g, glow.color.b, glow.centre * 0.3) }
            GradientStop { position: 1.0; color: Qt.rgba(glow.color.r, glow.color.g, glow.color.b, 0) }
        }
        PathAngleArc {
            centerX: glow.width / 2; centerY: glow.height / 2
            radiusX: glow.width / 2; radiusY: glow.height / 2
            startAngle: 0; sweepAngle: 360
        }
    }
}
