import QtQuick
import QtQuick.Shapes

// Soft radial light spot (vector, resolution independent, no image asset).
// Static geometry – animate it via opacity / x / y / scale only, which the
// scene graph handles without re-tessellating.
Shape {
    id: blob

    property color color: "#3BA9FF"
    property real intensity: 1.0     // centre alpha
    property real falloff: 0.45      // position of the mid stop (0..1)

    width: 400
    height: 400

    ShapePath {
        strokeWidth: -1
        strokeColor: "transparent"
        fillGradient: RadialGradient {
            centerX: blob.width / 2
            centerY: blob.height / 2
            focalX: centerX
            focalY: centerY
            centerRadius: Math.min(blob.width, blob.height) / 2
            focalRadius: 0
            GradientStop { position: 0.0; color: Qt.rgba(blob.color.r, blob.color.g, blob.color.b, blob.intensity) }
            GradientStop { position: blob.falloff; color: Qt.rgba(blob.color.r, blob.color.g, blob.color.b, blob.intensity * 0.28) }
            GradientStop { position: 1.0; color: Qt.rgba(blob.color.r, blob.color.g, blob.color.b, 0) }
        }

        PathAngleArc {
            centerX: blob.width / 2
            centerY: blob.height / 2
            radiusX: blob.width / 2
            radiusY: blob.height / 2
            startAngle: 0
            sweepAngle: 360
        }
    }
}
