pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

// Central emblem: aperture logo inside a slowly rotating calibration ring.
// mode: "idle", "active" (authenticating), "success", "error", "standby"
Item {
    id: ring

    property var theme
    property string mode: "idle"
    property bool animated: true

    implicitWidth: 240
    implicitHeight: 240

    readonly property real r: Math.min(width, height) / 2
    property color accent: mode === "error" ? theme.error
                                  : mode === "success" ? theme.blue
                                  : theme.orange
    readonly property string coreMode: mode === "error" ? "error"
                                     : mode === "success" ? "success"
                                     : mode === "active" ? "active" : "idle"
    // Faster spin while the login is being verified.
    readonly property real speed: mode === "active" ? 6 : 1

    Behavior on accent { ColorAnimation { duration: ring.theme.normal } }

    // ---- crosshair lines extending beyond the ring (static) ----
    Repeater {
        model: [0, 90, 180, 270]
        Rectangle {
            required property int modelData
            width: ring.r * 0.32
            height: 1
            color: ring.theme.alpha(ring.accent, 0.45)
            x: ring.width / 2 - width / 2 + Math.cos(modelData * Math.PI / 180) * ring.r * 1.08
            y: ring.height / 2 + Math.sin(modelData * Math.PI / 180) * ring.r * 1.08
            rotation: modelData
        }
    }

    // ---- outer tick ring: 72 marks, every 6th longer ----
    Item {
        id: ticks
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        Repeater {
            model: 72
            Rectangle {
                required property int index
                readonly property bool major: index % 6 === 0
                width: 1.5
                height: major ? ring.r * 0.07 : ring.r * 0.035
                antialiasing: true
                color: major ? ring.theme.alpha(ring.theme.text, 0.55) : ring.theme.alpha(ring.theme.text, 0.25)
                x: ring.width / 2 - width / 2
                y: ring.height / 2 - ring.r * 0.99
                transform: Rotation {
                    origin.x: 0.75
                    origin.y: ring.r * 0.99
                    angle: index * 5
                }
            }
        }

        RotationAnimation on rotation {
            running: ring.animated && ring.visible
            from: 0; to: 360
            duration: 240000 / ring.speed
            loops: Animation.Infinite
        }
    }

    // ---- orange calibration segments (counter-rotating, pulsing) ----
    Shape {
        id: segments
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        readonly property real segR: ring.r * 0.86
        readonly property real segW: Math.max(3, ring.r * 0.045)

        // Four arcs with uneven gaps, like a mechanical calibration ring.
        ShapePath {
            strokeColor: ring.accent; strokeWidth: segments.segW; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: segments.segR; radiusY: segments.segR; startAngle: -80; sweepAngle: 70 }
        }
        ShapePath {
            strokeColor: ring.accent; strokeWidth: segments.segW; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: segments.segR; radiusY: segments.segR; startAngle: 5; sweepAngle: 95 }
        }
        ShapePath {
            strokeColor: ring.accent; strokeWidth: segments.segW; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: segments.segR; radiusY: segments.segR; startAngle: 118; sweepAngle: 52 }
        }
        ShapePath {
            strokeColor: ring.accent; strokeWidth: segments.segW; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: segments.segR; radiusY: segments.segR; startAngle: 185; sweepAngle: 80 }
        }
        // Thin inner guide circle.
        ShapePath {
            strokeColor: ring.theme.alpha(ring.theme.text, 0.18); strokeWidth: 1; fillColor: "transparent"
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: ring.r * 0.76; radiusY: ring.r * 0.76; startAngle: 0; sweepAngle: 360 }
        }

        RotationAnimation on rotation {
            running: ring.animated && ring.visible
            from: 360; to: 0
            duration: 150000 / ring.speed
            loops: Animation.Infinite
        }

        SequentialAnimation on opacity {
            running: ring.animated && ring.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.7; duration: 2400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
        }
    }

    // ---- dark disc, core and aperture logo ----
    Rectangle {
        anchors.centerIn: parent
        width: ring.r * 1.42
        height: width
        radius: width / 2
        color: ring.theme.alpha(ring.theme.base, 0.75)
        border.color: ring.theme.alpha(ring.theme.text, 0.08)
        border.width: 1
    }

    // The core shines through the hole in the middle of the logo.
    CoreWidget {
        anchors.centerIn: parent
        theme: ring.theme
        mode: ring.coreMode
        animated: ring.animated
        size: ring.r * 0.75
    }

    Image {
        id: logo
        anchors.centerIn: parent
        width: ring.r * 1.22
        height: width
        source: Qt.resolvedUrl("../assets/aperture-logo.svg")
        sourceSize: Qt.size(width * 2, height * 2)
        smooth: true
        opacity: 0.9

        // The iris "tightens" briefly while authenticating / on success.
        Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        rotation: ring.mode === "active" ? 22.5 : ring.mode === "success" ? 45 : 0
    }
}
