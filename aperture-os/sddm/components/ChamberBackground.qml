pragma ComponentBehavior: Bound
import QtQuick

// Test chamber backdrop: one compressed background photo plus cheap
// procedural layers (colour grade, light drift, core/portal glows, grid,
// scanlines, vignette). All animations only touch opacity/position.
Item {
    id: bg

    property var theme
    property string coreMode: "idle"     // forwarded to the robot-eye core
    property real extraDim: 0            // 0..1, used by standby mode
    property bool animated: true

    // ---- mapping of image-relative coordinates (PreserveAspectCrop) ----
    readonly property real imgW: photo.implicitWidth > 0 ? photo.implicitWidth : 1672
    readonly property real imgH: photo.implicitHeight > 0 ? photo.implicitHeight : 941
    readonly property real cropScale: Math.max(width / imgW, height / imgH)
    // Glow sizes are authored for the 1672 px wide source art; k keeps them
    // correct for any background resolution.
    readonly property real k: cropScale * imgW / 1672
    function mapX(rx) { return (width - imgW * cropScale) / 2 + rx * imgW * cropScale }
    function mapY(ry) { return (height - imgH * cropScale) / 2 + ry * imgH * cropScale }

    Rectangle {
        anchors.fill: parent
        color: bg.theme.base
    }

    Image {
        id: photo
        anchors.fill: parent
        source: {
            const path = bg.theme.backgroundImage
            if (path.length === 0)
                return ""
            // Absolute paths and URLs are used as-is, others are theme-relative.
            if (path.startsWith("/"))
                return "file://" + path
            if (path.indexOf("://") > 0)
                return path
            return Qt.resolvedUrl("../" + path)
        }
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
    }

    // ---- scene glows anchored to features of the default background ----
    Item {
        anchors.fill: parent
        visible: bg.theme.sceneGlows && photo.status === Image.Ready

        CoreWidget {
            theme: bg.theme
            mode: bg.coreMode
            animated: bg.animated
            size: Math.max(60, bg.k * 150)
            x: bg.mapX(bg.theme.coreX) - width / 2
            y: bg.mapY(bg.theme.coreY) - height / 2
        }

        // Portal energy flicker: irregular, low-amplitude opacity changes.
        GlowBlob {
            id: portalGlow
            width: bg.k * 260
            height: bg.k * 520
            x: bg.mapX(bg.theme.portalX) - width / 2
            y: bg.mapY(bg.theme.portalY) - height / 2
            color: bg.theme.orange
            intensity: 0.32
            falloff: 0.35

            SequentialAnimation on opacity {
                running: bg.animated
                loops: Animation.Infinite
                NumberAnimation { to: 0.75; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.95; duration: 140 }
                NumberAnimation { to: 0.7; duration: 90 }
                NumberAnimation { to: 1.0; duration: 2200; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 900 }
            }
        }
    }

    // ---- colour grade: cold blue, darker top/bottom ----
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.04, 0.07, 0.55) }
            GradientStop { position: 0.35; color: Qt.rgba(0.03, 0.06, 0.10, 0.18) }
            GradientStop { position: 0.75; color: Qt.rgba(0.02, 0.04, 0.07, 0.30) }
            GradientStop { position: 1.0; color: Qt.rgba(0.01, 0.02, 0.04, 0.75) }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: Math.min(0.92, bg.theme.backgroundDim + bg.extraDim * 0.45)
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
    }

    // ---- slow light / fog drift ----
    GlowBlob {
        id: fogA
        width: bg.width * 0.9
        height: bg.height * 0.75
        y: bg.height * 0.18
        color: bg.theme.blue
        intensity: 0.10
        falloff: 0.5
        x: bg.width * 0.05
        // Ping-pong drift, ~1 minute per direction.
        SequentialAnimation on x {
            running: bg.animated
            loops: Animation.Infinite
            NumberAnimation { to: bg.width * 0.18; duration: 65000; easing.type: Easing.InOutSine }
            NumberAnimation { to: bg.width * -0.05; duration: 65000; easing.type: Easing.InOutSine }
        }
    }
    GlowBlob {
        width: bg.width * 0.5
        height: bg.height * 0.5
        x: bg.width * 0.28
        y: -bg.height * 0.12
        color: bg.theme.blueBright
        intensity: 0.08
        SequentialAnimation on opacity {
            running: bg.animated
            loops: Animation.Infinite
            NumberAnimation { to: 0.45; duration: 9000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 9000; easing.type: Easing.InOutSine }
        }
    }

    // ---- technical grid (static) ----
    Item {
        id: grid
        anchors.fill: parent
        visible: bg.theme.showGrid
        opacity: 0.5
        readonly property real step: bg.theme.px(64)

        Repeater {
            model: Math.ceil(bg.width / grid.step)
            Rectangle {
                required property int index
                x: index * grid.step
                width: 1
                height: bg.height
                color: Qt.rgba(0.6, 0.8, 1, index % 4 === 0 ? 0.05 : 0.025)
            }
        }
        Repeater {
            model: Math.ceil(bg.height / grid.step)
            Rectangle {
                required property int index
                y: index * grid.step
                width: bg.width
                height: 1
                color: Qt.rgba(0.6, 0.8, 1, index % 4 === 0 ? 0.05 : 0.025)
            }
        }
    }

    // ---- scanlines: a 1x4 px tile repeated by the GPU ----
    Image {
        anchors.fill: parent
        visible: bg.theme.showScanlines
        source: Qt.resolvedUrl("../assets/scanlines.png")
        fillMode: Image.Tile
        opacity: 0.22
        smooth: false
    }

    // A faint bright line that sweeps down every ~20 s (CRT feel).
    Rectangle {
        id: sweep
        visible: bg.theme.showScanlines && bg.animated
        width: parent.width
        height: Math.max(2, bg.theme.px(3))
        y: -height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(0.7, 0.88, 1, 0.07) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        SequentialAnimation on y {
            running: sweep.visible
            loops: Animation.Infinite
            PauseAnimation { duration: 8000 }
            NumberAnimation { from: -sweep.height; to: bg.height; duration: 11000; easing.type: Easing.Linear }
        }
    }

    // ---- vignette ----
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.55) }
            GradientStop { position: 0.22; color: "transparent" }
            GradientStop { position: 0.78; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
        }
    }
}
