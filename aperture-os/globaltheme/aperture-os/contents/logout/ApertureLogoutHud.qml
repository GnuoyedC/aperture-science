/*
    Aperture OS logout overlay: "Aperture Shutdown" sequence.
    Decorative only - all actions stay in Logout.qml.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtCore

Item {
    id: hud

    property ApertureTokens tk: ApertureTokens {}
    property string mode: "menu"          // menu | reboot | halt | logout
    property bool counting: false
    property int remaining: 0
    property real frameTop: height / 2
    property real frameBottom: height / 2
    property real frameWidth: px(520)

    readonly property bool animate: !tk.reduceMotion
    readonly property real u: Math.max(0.75, Math.min(width / 1920, height / 1080))
    function px(v) { return Math.round(v * u) }

    readonly property string title: ({
        "reboot": "RESTART SEQUENCE",
        "halt": "APERTURE SHUTDOWN",
        "logout": "SESSION TERMINATION",
        "menu": "APERTURE SHUTDOWN"
    })[mode]

    // --- chamber backdrop (opaque enough that windows behind do not distract) ---------
    Rectangle { anchors.fill: parent; color: hud.tk.alpha(hud.tk.background, 0.93) }
    Image {
        anchors.fill: parent
        source: StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
                + "/wallpapers/ApertureTestChamber/contents/images/2560x1440.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 0.40 : 0
        Behavior on opacity { NumberAnimation { duration: hud.tk.slow } }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: hud.tk.alpha(hud.tk.background, 0.35) }
            GradientStop { position: 1.0; color: hud.tk.alpha(hud.tk.background, 0.80) }
        }
    }

    // --- header -------------------------------------------------------------------------
    RowLayout {
        anchors { left: parent.left; top: parent.top; margins: hud.px(48) }
        spacing: hud.px(18)
        Image {
            source: "aperture-logo.svg"
            sourceSize: Qt.size(hud.px(56), hud.px(56))
            Layout.preferredWidth: hud.px(56); Layout.preferredHeight: hud.px(56)
            opacity: 0.92
            RotationAnimator on rotation {
                running: hud.animate && hud.counting
                from: 0; to: -360; duration: 6000; loops: Animation.Infinite
            }
        }
        ColumnLayout {
            spacing: hud.px(2)
            Text {
                text: hud.title
                color: hud.tk.text
                font.family: hud.tk.display; font.pixelSize: hud.px(28); font.weight: Font.DemiBold
                font.letterSpacing: hud.px(3)
            }
            Text {
                text: "APERTURE OS  ·  TEST CHAMBER 01"
                color: hud.tk.textMuted
                font.family: hud.tk.mono; font.pixelSize: hud.px(13); font.letterSpacing: hud.px(2)
            }
        }
    }

    // --- frame behind the user + buttons --------------------------------------------------
    Item {
        id: frame
        x: (hud.width - hud.frameWidth) / 2
        y: hud.frameTop - hud.px(48)
        width: hud.frameWidth
        height: hud.frameBottom - hud.frameTop + hud.px(96)

        Rectangle {
            anchors.fill: parent
            color: hud.tk.alpha(hud.tk.surface, 0.80)
            border.color: hud.tk.border
            border.width: 1
            radius: hud.tk.radiusFrame
        }
        Repeater {
            model: 4
            Item {
                id: bracket
                readonly property bool isRight: index % 2 === 1
                readonly property bool isBottom: index > 1
                x: isRight ? frame.width - width : 0
                y: isBottom ? frame.height - height : 0
                width: hud.px(18); height: hud.px(18)
                Rectangle { width: parent.width; height: 2; y: bracket.isBottom ? bracket.height - 2 : 0; color: hud.tk.orange }
                Rectangle { width: 2; height: parent.height; x: bracket.isRight ? bracket.width - 2 : 0; color: hud.tk.orange }
            }
        }
        Text {
            anchors { left: parent.left; top: parent.top; margins: hud.px(18) }
            text: "◉ TEST SUBJECT"
            color: hud.tk.orange
            font.family: hud.tk.mono; font.pixelSize: hud.px(12); font.letterSpacing: hud.px(2)
        }
        Text {
            anchors { right: parent.right; top: parent.top; margins: hud.px(18) }
            text: "[ POWER CONTROL ]"
            color: hud.tk.textMuted
            font.family: hud.tk.mono; font.pixelSize: hud.px(12); font.letterSpacing: hud.px(2)
        }
    }

    // --- status line ------------------------------------------------------------------------
    RowLayout {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: hud.px(64) }
        spacing: hud.px(12)
        Rectangle {
            width: hud.px(9); height: width; radius: width / 2
            color: hud.counting ? hud.tk.warning : hud.tk.blue
            SequentialAnimation on opacity {
                running: hud.animate
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: hud.counting ? 500 : hud.tk.pulse / 2; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: hud.counting ? 500 : hud.tk.pulse / 2; easing.type: Easing.InOutSine }
            }
        }
        Text {
            text: hud.counting ? "STATUS: SEQUENCE ARMED  ·  T-" + hud.remaining + " s"
                               : "STATUS: AWAITING CONFIRMATION  ·  ESC TO ABORT"
            color: hud.counting ? hud.tk.warning : hud.tk.blue
            font.family: hud.tk.mono; font.pixelSize: hud.px(14); font.letterSpacing: hud.px(3)
        }
    }
}
