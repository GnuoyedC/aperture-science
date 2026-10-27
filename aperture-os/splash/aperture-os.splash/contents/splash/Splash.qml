/*
    Aperture OS splash: short initialisation sequence after login.

    KSplash raises `stage` from 1 to 6 while Plasma starts; the splash closes
    automatically when the desktop is ready. Lines are bound to the stages, so the
    splash never makes you wait longer than Plasma itself needs.

    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick

Rectangle {
    id: root
    color: tk.background

    property int stage: 0
    readonly property ApertureTokens tk: ApertureTokens {}
    readonly property bool animate: !tk.reduceMotion
    readonly property real u: Math.max(0.75, Math.min(width / 1920, height / 1080))
    function px(v) { return Math.round(v * u) }

    // boot log: [text, stage at which the line is complete]
    readonly property var lines: [
        ["INITIALIZING APERTURE OS", 1],
        ["LOADING TEST CHAMBER", 2],
        ["CALIBRATING PORTAL DEVICE", 3],
        ["VERIFYING TEST SUBJECT", 4],
    ]
    readonly property bool ready: stage >= 5

    onStageChanged: if (stage === 1) intro.start()

    // --- atmosphere: the test chamber, heavily dimmed -----------------------------------
    Image {
        anchors.fill: parent
        source: "images/background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        opacity: 0.22
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.tk.alpha(root.tk.background, 0.35) }
            GradientStop { position: 1.0; color: root.tk.alpha(root.tk.background, 0.85) }
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Column {
            id: bootLog
            anchors.centerIn: parent
            width: root.px(560)
            spacing: root.px(12)

            Row {
                spacing: root.px(18)
                Image {
                    id: logo
                    source: "images/aperture-logo.svg"
                    width: root.px(54); height: width
                    sourceSize: Qt.size(width, height)
                    RotationAnimator on rotation {
                        running: root.animate && !root.ready
                        from: 0; to: 360; duration: 9000; loops: Animation.Infinite
                    }
                }
                Column {
                    anchors.verticalCenter: logo.verticalCenter
                    spacing: root.px(2)
                    Text {
                        text: "APERTURE LABORATORIES"
                        color: root.tk.text
                        font.family: root.tk.display; font.pixelSize: root.px(30); font.weight: Font.DemiBold
                        font.letterSpacing: root.px(4)
                    }
                    Text {
                        text: "AUTOMATED TESTING FACILITY"
                        color: root.tk.textMuted
                        font.family: root.tk.mono; font.pixelSize: root.px(12); font.letterSpacing: root.px(3)
                    }
                }
            }

            Item { width: 1; height: root.px(18) }

            Repeater {
                model: root.lines
                Row {
                    required property var modelData
                    readonly property bool done: root.stage >= modelData[1]
                    readonly property bool active: root.stage === modelData[1] - 1
                    spacing: 0
                    opacity: done || active ? 1 : 0.0
                    Behavior on opacity { NumberAnimation { duration: root.tk.fast } }
                    Text {
                        width: root.px(400)
                        text: modelData[0] + " " + ".".repeat(40)
                        clip: true
                        elide: Text.ElideNone
                        color: root.tk.textMuted
                        font.family: root.tk.mono; font.pixelSize: root.px(14); font.letterSpacing: root.px(1)
                    }
                    Text {
                        width: root.px(60)
                        horizontalAlignment: Text.AlignRight
                        text: parent.done ? "OK" : "··"
                        color: parent.done ? root.tk.success : root.tk.orange
                        font.family: root.tk.mono; font.pixelSize: root.px(14); font.weight: Font.Bold
                    }
                }
            }

            Item { width: 1; height: root.px(10) }

            // progress rail
            Rectangle {
                width: bootLog.width; height: 2
                color: root.tk.border
                Rectangle {
                    height: parent.height
                    width: parent.width * Math.min(1, root.stage / 5)
                    color: root.ready ? root.tk.blue : root.tk.orange
                    Behavior on width { NumberAnimation { duration: root.tk.slow; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: root.tk.normal } }
                }
            }

            Item { width: 1; height: root.px(10) }

            Text {
                text: root.ready ? "SYSTEM READY" : "STAND BY"
                color: root.ready ? root.tk.blue : root.tk.textMuted
                font.family: root.tk.mono; font.pixelSize: root.px(14); font.letterSpacing: root.px(3)
            }
            Text {
                text: "WELCOME, TEST SUBJECT"
                color: root.tk.text
                opacity: root.ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: root.tk.normal } }
                font.family: root.tk.display; font.pixelSize: root.px(24); font.weight: Font.DemiBold
                font.letterSpacing: root.px(3)
                Text {
                    // blinking console cursor
                    anchors.left: parent.right
                    anchors.leftMargin: root.px(6)
                    text: "_"
                    color: root.tk.orange
                    font: parent.font
                    SequentialAnimation on opacity {
                        running: root.animate && root.ready
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 1; }
                        PauseAnimation { duration: 450 }
                        NumberAnimation { to: 1; duration: 1; }
                        PauseAnimation { duration: 450 }
                    }
                }
            }
        }
    }

    OpacityAnimator {
        id: intro
        target: content
        from: 0; to: 1
        duration: root.animate ? root.tk.slow : 1
        easing.type: Easing.OutQuad
    }
}
