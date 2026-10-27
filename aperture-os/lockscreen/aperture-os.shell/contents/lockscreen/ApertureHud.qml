/*
    Aperture OS lock screen overlay: facility header, clock, security status.
    Purely decorative - every authentication path stays in LockScreenUi/MainBlock.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

Item {
    id: hud

    property ApertureTokens tk: ApertureTokens {}
    property bool uiVisible: false
    property bool denied: false            // set for a few seconds after a failed attempt
    property string userName: ""
    property real panelTop: height / 2      // geometry of the authentication block
    property real panelBottom: height / 2
    property real panelOpacity: 0

    readonly property bool animate: !tk.reduceMotion
    readonly property real u: Math.max(0.75, Math.min(width / 1920, height / 1080))
    function px(v) { return Math.round(v * u) }

    property date now: new Date()
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: hud.now = new Date()
    }

    // --- tinted safety glass over the wallpaper --------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: hud.tk.alpha(hud.tk.background, 0.55) }
            GradientStop { position: 0.45; color: hud.tk.alpha(hud.tk.background, 0.25) }
            GradientStop { position: 1.0; color: hud.tk.alpha(hud.tk.background, 0.70) }
        }
    }

    // red flash on a failed attempt ("short red glitch")
    Rectangle {
        id: deniedFlash
        anchors.fill: parent
        color: hud.tk.error
        opacity: 0
        SequentialAnimation {
            id: glitch
            NumberAnimation { target: deniedFlash; property: "opacity"; to: 0.16; duration: 40 }
            NumberAnimation { target: deniedFlash; property: "opacity"; to: 0.04; duration: 60 }
            NumberAnimation { target: deniedFlash; property: "opacity"; to: 0.12; duration: 40 }
            NumberAnimation { target: deniedFlash; property: "opacity"; to: 0; duration: 260 }
        }
    }
    onDeniedChanged: if (denied && animate) glitch.restart()

    // --- header (top left) ----------------------------------------------------------------
    RowLayout {
        anchors { left: parent.left; top: parent.top; margins: hud.px(48) }
        spacing: hud.px(18)
        Image {
            source: "aperture-logo.svg"
            sourceSize: Qt.size(hud.px(56), hud.px(56))
            Layout.preferredWidth: hud.px(56); Layout.preferredHeight: hud.px(56)
            opacity: 0.92
        }
        ColumnLayout {
            spacing: hud.px(2)
            Text {
                text: "APERTURE SECURITY SYSTEM"
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

    // --- clock (top right) ------------------------------------------------------------------
    ColumnLayout {
        anchors { right: parent.right; top: parent.top; margins: hud.px(48) }
        spacing: hud.px(2)
        Text {
            Layout.alignment: Qt.AlignRight
            text: Qt.formatTime(hud.now, "HH:mm")
            color: hud.tk.text
            font.family: hud.tk.display; font.pixelSize: hud.px(72); font.weight: Font.Medium
        }
        Text {
            Layout.alignment: Qt.AlignRight
            // long date in the system language ("Sonntag, 4. Oktober 2026" / "Sunday, October 4, 2026")
            text: hud.now.toLocaleDateString(Qt.locale(), Locale.LongFormat).toUpperCase()
            color: hud.tk.textMuted
            font.family: hud.tk.mono; font.pixelSize: hud.px(13); font.letterSpacing: hud.px(1)
        }
    }

    // --- authentication frame behind MainBlock --------------------------------------------------
    Item {
        id: frame
        readonly property real w: hud.px(460)
        x: (hud.width - w) / 2
        y: hud.panelTop - hud.px(64)
        width: w
        height: Math.max(hud.px(200), hud.panelBottom - hud.panelTop + hud.px(96))
        opacity: hud.panelOpacity
        visible: opacity > 0

        Rectangle {
            anchors.fill: parent
            color: hud.tk.alpha(hud.tk.surface, 0.86)
            border.color: hud.denied ? hud.tk.error : hud.tk.border
            border.width: 1
            radius: hud.tk.radiusFrame
            Behavior on border.color { ColorAnimation { duration: hud.tk.normal } }
        }
        // corner brackets
        Repeater {
            model: 4
            Item {
                id: bracket
                readonly property bool isRight: index % 2 === 1
                readonly property bool isBottom: index > 1
                x: isRight ? frame.width - width : 0
                y: isBottom ? frame.height - height : 0
                width: hud.px(18); height: hud.px(18)
                Rectangle { width: parent.width; height: 2; y: bracket.isBottom ? bracket.height - 2 : 0; color: hud.denied ? hud.tk.error : hud.tk.orange }
                Rectangle { width: 2; height: parent.height; x: bracket.isRight ? bracket.width - 2 : 0; color: hud.denied ? hud.tk.error : hud.tk.orange }
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
            text: "[ AUTHENTICATION ]"
            color: hud.tk.textMuted
            font.family: hud.tk.mono; font.pixelSize: hud.px(12); font.letterSpacing: hud.px(2)
        }
    }

    // --- status line (bottom centre) ----------------------------------------------------------
    RowLayout {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: hud.px(64) }
        spacing: hud.px(12)
        Rectangle {
            id: led
            width: hud.px(9); height: width; radius: width / 2
            color: hud.denied ? hud.tk.error : hud.tk.blue
            SequentialAnimation on opacity {
                running: hud.animate && !hud.denied
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: hud.tk.pulse / 2; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: hud.tk.pulse / 2; easing.type: Easing.InOutSine }
            }
        }
        Text {
            text: hud.denied ? "STATUS: ACCESS DENIED" : "STATUS: LOCKED"
            color: hud.denied ? hud.tk.error : hud.tk.blue
            font.family: hud.tk.mono; font.pixelSize: hud.px(14); font.letterSpacing: hud.px(3)
        }
        Text {
            visible: hud.userName.length > 0
            text: "·  SUBJECT " + hud.userName.toUpperCase()
            color: hud.tk.textMuted
            font.family: hud.tk.mono; font.pixelSize: hud.px(14); font.letterSpacing: hud.px(3)
        }
    }
}
