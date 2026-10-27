import QtQuick

// Top-right HUD: chamber id, clock, date and a small system status block
// that occasionally cycles through facility messages.
Item {
    id: hud

    property var theme
    property var strings
    property bool animated: true
    property bool compact: false        // standby: only id/clock/date

    implicitWidth: theme.px(260)
    implicitHeight: column.implicitHeight

    property date now: new Date()
    property int statusIndex: 0

    Timer {
        // The clock shows minutes only, but ticking every second keeps the
        // minute change punctual. Formatting a string per second is negligible.
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: hud.now = new Date()
    }

    // "Occasional HUD updates": swap the status line every 9 s.
    Timer {
        interval: 9000
        running: hud.animated && !hud.compact
        repeat: true
        onTriggered: statusSwap.restart()
    }

    SequentialAnimation {
        id: statusSwap
        NumberAnimation { target: statusLine; property: "opacity"; to: 0; duration: 220 }
        ScriptAction {
            script: {
                const list = hud.strings.tr("hud.status")
                hud.statusIndex = (hud.statusIndex + 1) % list.length
            }
        }
        NumberAnimation { target: statusLine; property: "opacity"; to: 1; duration: 220 }
    }

    Column {
        id: column
        anchors.right: parent.right
        width: parent.width
        spacing: hud.theme.px(4)

        Text {
            text: hud.theme.chamberId
            color: hud.theme.text
            opacity: 0.85
            font.family: hud.theme.font
            font.pixelSize: hud.theme.px(16)
        }
        Text {
            text: Qt.formatTime(hud.now, "HH:mm")
            color: hud.theme.text
            font.family: hud.theme.display
            font.pixelSize: hud.theme.px(60)
            font.weight: Font.Medium
            font.letterSpacing: hud.theme.px(2)
        }
        Text {
            text: hud.now.toLocaleDateString(Qt.locale(hud.strings.localeName), "dd. MMM yyyy")
            color: hud.theme.text
            opacity: 0.85
            font.family: hud.theme.font
            font.pixelSize: hud.theme.px(17)
        }

        Item { width: 1; height: hud.theme.px(10) }

        // Divider with an orange marker that slides along slowly.
        Item {
            width: parent.width
            height: 2
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 1
                color: hud.theme.alpha(hud.theme.text, 0.25)
            }
            Rectangle {
                id: marker
                width: hud.theme.px(40); height: 2
                color: hud.theme.text
                SequentialAnimation on x {
                    running: hud.animated
                    loops: Animation.Infinite
                    NumberAnimation { to: hud.width - marker.width; duration: 14000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 14000; easing.type: Easing.InOutSine }
                }
            }
        }

        Item { width: 1; height: hud.theme.px(8) }

        Row {
            spacing: hud.theme.px(12)
            opacity: hud.compact ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: hud.theme.slow } }

            Image {
                width: hud.theme.px(28); height: width
                sourceSize: Qt.size(width * 2, height * 2)
                source: Qt.resolvedUrl("../assets/aperture-logo.svg")
                opacity: 0.8
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 2; height: hud.theme.px(40)
                color: hud.theme.orange
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                spacing: hud.theme.px(2)
                anchors.verticalCenter: parent.verticalCenter
                Row {
                    spacing: hud.theme.px(6)
                    Text {
                        text: hud.theme.osName
                        color: hud.theme.muted
                        font.family: hud.theme.mono
                        font.pixelSize: hud.theme.px(11)
                    }
                    // Slow blinking "online" dot.
                    Rectangle {
                        width: hud.theme.px(6); height: width; radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: hud.theme.blue
                        SequentialAnimation on opacity {
                            running: hud.animated
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 1400 }
                            NumberAnimation { to: 1.0; duration: 1400 }
                        }
                    }
                    Text {
                        text: hud.strings.tr("hud.online")
                        color: hud.theme.muted
                        font.family: hud.theme.mono
                        font.pixelSize: hud.theme.px(11)
                    }
                }
                Text {
                    text: hud.strings.tr("hud.host") + " // " + (typeof sddm !== "undefined" ? sddm.hostName : "localhost")
                    color: hud.theme.muted
                    font.family: hud.theme.mono
                    font.pixelSize: hud.theme.px(11)
                }
                Text {
                    id: statusLine
                    text: {
                        const list = hud.strings.tr("hud.status")
                        return "> " + list[hud.statusIndex % list.length]
                    }
                    color: hud.theme.orange
                    opacity: 1
                    font.family: hud.theme.mono
                    font.pixelSize: hud.theme.px(11)
                }
            }
        }
    }
}
