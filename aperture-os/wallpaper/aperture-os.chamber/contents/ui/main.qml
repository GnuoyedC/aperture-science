/*
    Aperture OS - animated test chamber wallpaper.

    The photo provides the atmosphere; a few vector effects add life (the other
    motifs get their own effect scenes in scenes/, built from Spot/Tube/Dust/Cutout):
      - the robot core breathes (blue, ~5 s period)
      - light runs along the orange ring of the central cylinder (photo pixels)
      - the light shaft below the core swells slowly, rare fluorescent flicker
      - the doorway behind the companion cube breathes, short tube flicker
      - the portal rim shimmers (orange)
      - a few dust particles drift through the light cone
      - a large cold light field drifts slowly (~2 min)
    Performance: no shaders, no QML animations running at display refresh rate.
    One Timer ticks at `FrameRate` (default 10 Hz) and only changes opacity /
    position / arc angles of small shapes. Animate=false gives a static wallpaper.

    Framing: `Mirror` flips the scene horizontally (note: the lettering in the
    image is mirrored too), `Zoom` (1..2) with `FocusX`/`FocusY` (0..1) picks a
    different crop - e.g. core + portal on the laptop screen.

    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Shapes
import QtCore
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    // Motif: "chamber" = built-in photo with the hand-tuned effects below; the
    // other ids are the wallpaper packages of this repo (installed under
    // ~/.local/share/wallpapers/<id>) with an effect scene in scenes/<id>.qml.
    readonly property string scene: String(root.configuration.Scene || "chamber")
    readonly property bool customImage: String(root.configuration.Image || "").length > 0
    readonly property string motifSize: {
        const px = Math.max(width, height * 16 / 9) * Screen.devicePixelRatio
        return px <= 1950 ? "1920x1080" : (px <= 2600 ? "2560x1440" : "3840x2160")
    }
    readonly property string imageSource: {
        if (customImage) {
            const p = String(root.configuration.Image)
            return p.startsWith("/") ? "file://" + p : p
        }
        if (scene !== "chamber")
            return StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
                   + "/wallpapers/" + scene + "/contents/images/" + motifSize + ".jpg"
        return Qt.resolvedUrl("../images/chamber.jpg")
    }
    readonly property bool builtInImage: !customImage && scene === "chamber"
    readonly property bool animate: root.configuration.Animate
    readonly property real intensity: Math.max(0, Math.min(1, root.configuration.Intensity))
    readonly property int fps: Math.max(1, Math.min(30, root.configuration.FrameRate))
    readonly property bool mirror: root.configuration.Mirror
    readonly property real zoom: Math.max(1, Math.min(2, root.configuration.Zoom))
    readonly property real focusX: Math.max(0, Math.min(1, root.configuration.FocusX))
    readonly property real focusY: Math.max(0, Math.min(1, root.configuration.FocusY))

    // Token colours (see design/tokens.json)
    readonly property color blue: "#00AEEF"
    readonly property color blueBright: "#5CCDF7"
    readonly property color orange: "#FF7800"
    readonly property color orangeBright: "#FF9A3D"
    readonly property color background: "#070B0F"

    // ---- image-relative coordinates (crop + zoom + focus + mirror) -------------------
    readonly property real imgW: photo.implicitWidth > 0 ? photo.implicitWidth : 2560
    readonly property real imgH: photo.implicitHeight > 0 ? photo.implicitHeight : 1440
    readonly property real scale_: Math.max(width / imgW, height / imgH) * zoom
    readonly property real dispW: imgW * scale_
    readonly property real dispH: imgH * scale_
    readonly property real offX: (width - dispW) * focusX
    readonly property real offY: (height - dispH) * focusY
    readonly property real k: dispW / 1672   // scale relative to the source art
    function mapX(rx) { return offX + (mirror ? 1 - rx : rx) * dispW }
    function mapY(ry) { return offY + ry * dispH }

    // ---- clock -----------------------------------------------------------------------------------
    property real t: 0
    Timer {
        interval: Math.round(1000 / root.fps)
        repeat: true
        running: root.animate && root.visible
        onTriggered: root.t += interval / 1000
    }
    function wave(period, phase) { return 0.5 + 0.5 * Math.sin((root.t / period + (phase || 0)) * 2 * Math.PI) }
    function a(c, alpha) { return Qt.rgba(c.r, c.g, c.b, alpha) }
    readonly property real ringPhase: (root.t / 10) % 1

    Overlays { id: overlays }

    Rectangle { anchors.fill: parent; color: root.background }

    Image {
        id: photo
        x: root.offX; y: root.offY
        width: root.dispW; height: root.dispH
        source: root.imageSource
        fillMode: Image.Stretch
        mirror: root.mirror
        asynchronous: true
        smooth: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }

    Item {
        anchors.fill: parent
        visible: root.configuration.SceneGlows && root.builtInImage && photo.status === Image.Ready

        // ---- robot core: halo + bright eye, breathing
        readonly property real breath: root.wave(5)
        Glow {
            width: root.k * 260; height: width
            x: root.mapX(0.752) - width / 2
            y: root.mapY(0.211) - height / 2
            color: root.blue
            centre: 0.28
            opacity: root.intensity * (0.25 + 0.60 * parent.breath)
        }
        Glow {
            width: root.k * 90; height: width
            x: root.mapX(0.752) - width / 2
            y: root.mapY(0.211) - height / 2
            color: root.blueBright
            centre: 0.78
            opacity: root.intensity * (0.35 + 0.55 * parent.breath)
        }

        // ---- orange ring on the central cylinder
        // The ring's own lit pixels (cut from the photo by tools/make_overlays.py,
        // one PNG per 15° sector) brighten one after another: the light circles
        // the whole ring once per period (angles clockwise, 180 = left, 270 = top).
        // The front half has no lit pixels, so the light dips away there and
        // comes back on the left without a jump.
        Repeater {
            model: overlays.ring
            delegate: Image {
                required property var modelData
                readonly property real head: root.mirror ? 360 - 360 * root.ringPhase : 360 * root.ringPhase
                readonly property real dist: Math.abs(((modelData.angle - head) % 360 + 540) % 360 - 180)
                x: root.mapX(root.mirror ? modelData.x + modelData.w : modelData.x)
                y: root.mapY(modelData.y)
                width: modelData.w * root.dispW
                height: modelData.h * root.dispH
                source: modelData.src
                mirror: root.mirror
                smooth: true
                asynchronous: true
                opacity: Math.min(1, 0.25 + root.intensity) * (0.12 + 0.88 * Math.exp(-(dist * dist) / (2 * 22 * 22)))
            }
        }

        // ---- light shaft + corridor below the core: slow swell, rare short
        // fluorescent flicker (photo pixels, see tools/make_overlays.py)
        Image {
            readonly property var r: overlays.corridor
            // flicker: ~0.6 s dip every ~37 s
            readonly property real cycle: root.t % 37
            readonly property real flicker: cycle > 21 && cycle < 21.6
                ? 0.45 + 0.55 * Math.abs(Math.sin(cycle * 23)) : 1
            x: root.mapX(root.mirror ? r.x + r.w : r.x)
            y: root.mapY(r.y)
            width: r.w * root.dispW
            height: r.h * root.dispH
            source: r.src
            mirror: root.mirror
            smooth: true
            asynchronous: true
            opacity: root.intensity * (0.20 + 0.80 * root.wave(9, 0.25)) * flicker
        }

        // ---- lit doorway behind the companion cube: own slow swell (out of
        // phase with the shaft), now and then a short double flicker of the tubes
        Image {
            readonly property var r: overlays.doorway
            readonly property real cycle: (root.t + 11) % 29
            readonly property real flicker: (cycle > 14 && cycle < 14.25) || (cycle > 14.45 && cycle < 14.6) ? 0.35 : 1
            x: root.mapX(root.mirror ? r.x + r.w : r.x)
            y: root.mapY(r.y)
            width: r.w * root.dispW
            height: r.h * root.dispH
            source: r.src
            mirror: root.mirror
            smooth: true
            asynchronous: true
            // +8 % over the other lights (user feedback: barely noticeable)
            opacity: Math.min(1, root.intensity * 1.08 * (0.25 + 0.75 * root.wave(12, 0.6)) * flicker)
        }

        // ---- portal: energy glow + shimmering rim
        Glow {
            width: root.k * 240; height: root.k * 520
            x: root.mapX(0.971) - width / 2
            y: root.mapY(0.552) - height / 2
            color: root.orange
            centre: 0.34
            opacity: root.intensity * (0.55 + 0.30 * root.wave(4.3) + 0.15 * root.wave(0.9, 0.3))
        }
        Arc {
            width: root.dispW * 0.040; height: root.dispH * 0.360
            x: root.mapX(0.9705) - width / 2
            y: root.mapY(0.551) - height / 2
            color: root.a(root.orangeBright, 0.18 + 0.25 * root.wave(1.7))
            lineWidth: Math.max(1, root.k * 1.5)
            haloWidth: root.k * (8 + 3 * root.wave(2.9, 0.4))
            haloAlpha: 0.07 + 0.09 * root.wave(2.3, 0.2)
            opacity: root.intensity
        }

        // ---- dust in the light cone of the cylinder
        Repeater {
            model: 13
            delegate: Rectangle {
                required property int index
                // deterministic pseudo random per particle
                readonly property real r1: (Math.sin(index * 12.9898) * 43758.5453) % 1
                readonly property real r2: (Math.sin(index * 78.233) * 12543.1234) % 1
                readonly property real rr1: Math.abs(r1)
                readonly property real rr2: Math.abs(r2)
                readonly property real period: 26 + 22 * rr2               // s per rise
                readonly property real phase: (root.t / period + rr1) % 1    // 0 -> 1
                readonly property real baseX: 0.455 + 0.13 * rr1
                width: Math.max(1.5, root.k * (1.2 + 1.6 * rr2)); height: width
                radius: width / 2
                color: root.blueBright
                x: root.mapX(baseX + 0.006 * Math.sin((root.t / (9 + 5 * rr2) + rr1) * 2 * Math.PI)) - width / 2
                y: root.mapY(0.80 - 0.50 * phase) - height / 2
                opacity: root.intensity * (0.28 + 0.35 * rr2) * Math.sin(Math.PI * phase)
            }
        }
    }

    // effect scene of the chosen motif (scenes/<id>.qml, positions in source px)
    Loader {
        id: sceneLoader
        anchors.fill: parent
        visible: root.configuration.SceneGlows && photo.status === Image.Ready
        readonly property string wanted: !root.customImage && root.scene !== "chamber" ? root.scene : ""
        onWantedChanged: load()
        Component.onCompleted: load()
        function load() {
            if (wanted.length > 0)
                setSource("scenes/" + wanted + ".qml", { wp: root })
            else
                source = ""
        }
    }

    // slow cold light drift
    Glow {
        width: root.width * 0.9; height: root.height * 0.7
        y: root.height * 0.2
        x: root.width * (0.05 + 0.12 * Math.sin(root.t / 130 * 2 * Math.PI))
        color: root.blue
        centre: 0.08
        opacity: root.intensity
    }

    // gentle grade so the UI stays readable on top
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.03, 0.04, 0.06, 0.30) }
            GradientStop { position: 0.5; color: Qt.rgba(0.03, 0.04, 0.06, 0.05) }
            GradientStop { position: 1.0; color: Qt.rgba(0.03, 0.04, 0.06, 0.35) }
        }
    }
}
