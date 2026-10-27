import QtQuick

// Reduced "STANDBY TEST MODE" view shown after a period without input.
Item {
    id: standby

    property var theme
    property var strings
    property bool animated: true

    Column {
        anchors.centerIn: parent
        spacing: standby.theme.px(18)

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: standby.theme.px(130)
            height: width

            CoreWidget {
                anchors.centerIn: parent
                theme: standby.theme
                animated: standby.animated && standby.visible
                size: parent.width * 0.6
            }
            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/aperture-logo.svg")
                sourceSize: Qt.size(width * 2, height * 2)
                opacity: 0.85
                RotationAnimation on rotation {
                    running: standby.animated && standby.visible
                    from: 0; to: 360
                    duration: 120000
                    loops: Animation.Infinite
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: standby.strings.tr("standby.title")
            color: standby.theme.text
            font.family: standby.theme.mono
            font.pixelSize: standby.theme.px(18)
            font.letterSpacing: standby.theme.px(3)
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: standby.strings.tr("standbyHint")
            color: standby.theme.muted
            font.family: standby.theme.font
            font.pixelSize: standby.theme.px(13)
            SequentialAnimation on opacity {
                running: standby.animated && standby.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 2200; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 2200; easing.type: Easing.InOutSine }
            }
        }
    }
}
