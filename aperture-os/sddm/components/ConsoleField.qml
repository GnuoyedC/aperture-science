import QtQuick
import QtQuick.Controls.Basic

// Text input in console style: leading icon, optional trailing button and an
// orange glow while focused (red while `error` is set).
FocusScope {
    id: field

    property var theme
    property alias text: input.text
    property alias input: input
    property alias placeholderText: input.placeholderText
    property alias echoMode: input.echoMode
    property string iconSource: ""
    property string trailingIcon: ""
    property string trailingToolTip: ""
    property bool error: false

    signal accepted()
    signal trailingClicked()

    implicitWidth: theme.px(400)
    implicitHeight: theme.px(50)

    readonly property bool focused: input.activeFocus
    readonly property color accent: error ? theme.error : theme.orange

    // Outer glow (two soft frames, cheaper than a blur effect).
    Rectangle {
        anchors.fill: frame
        anchors.margins: -field.theme.px(5)
        radius: field.theme.px(6)
        color: "transparent"
        border.width: field.theme.px(5)
        border.color: field.theme.alpha(field.accent, 0.10)
        opacity: field.focused || field.error ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: field.theme.normal } }
    }
    Rectangle {
        anchors.fill: frame
        anchors.margins: -field.theme.px(2)
        radius: field.theme.px(4)
        color: "transparent"
        border.width: field.theme.px(2)
        border.color: field.theme.alpha(field.accent, 0.28)
        opacity: field.focused || field.error ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: field.theme.normal } }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: field.theme.px(3)
        color: field.theme.alpha(field.theme.field, 0.82)
        border.width: 1
        border.color: field.focused || field.error ? field.accent
                    : hover.hovered ? Qt.lighter(field.theme.line, 1.5) : field.theme.line
        Behavior on border.color { ColorAnimation { duration: field.theme.fast } }
    }

    HoverHandler { id: hover; cursorShape: Qt.IBeamCursor }

    Image {
        id: icon
        visible: field.iconSource.length > 0
        anchors.left: parent.left
        anchors.leftMargin: field.theme.px(16)
        anchors.verticalCenter: parent.verticalCenter
        width: field.theme.px(20)
        height: width
        sourceSize: Qt.size(width * 2, height * 2)
        source: field.iconSource
        opacity: field.focused ? 1 : 0.65
    }

    TextField {
        id: input
        focus: true
        anchors.left: icon.visible ? icon.right : parent.left
        anchors.leftMargin: field.theme.px(14)
        anchors.right: trailing.visible ? trailing.left : parent.right
        anchors.rightMargin: field.theme.px(8)
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        background: null
        padding: 0
        verticalAlignment: TextInput.AlignVCenter
        color: field.theme.text
        placeholderTextColor: field.theme.muted
        selectionColor: field.theme.alpha(field.theme.orange, 0.5)
        selectedTextColor: field.theme.text
        selectByMouse: true
        passwordCharacter: "•"
        font.family: field.theme.font
        font.pixelSize: field.theme.fontSize
        onAccepted: field.accepted()
    }

    // Optional trailing icon button (show password, user list, …).
    AbstractButton {
        id: trailing
        visible: field.trailingIcon.length > 0
        anchors.right: parent.right
        anchors.rightMargin: field.theme.px(8)
        anchors.verticalCenter: parent.verticalCenter
        width: field.theme.px(34)
        height: width
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        onClicked: field.trailingClicked()

        ToolTip.visible: hovered && field.trailingToolTip.length > 0
        ToolTip.text: field.trailingToolTip
        ToolTip.delay: 600

        background: Rectangle {
            radius: field.theme.px(3)
            color: trailing.hovered ? field.theme.alpha(field.theme.text, 0.08) : "transparent"
        }
        contentItem: Image {
            source: field.trailingIcon
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
            width: field.theme.px(18)
            height: width
            opacity: trailing.hovered ? 1 : 0.6
        }
    }
}
