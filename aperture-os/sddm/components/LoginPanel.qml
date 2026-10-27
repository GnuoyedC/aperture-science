pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic

// The login console: status header, username, password, login button,
// session and keyboard layout. The panel does not talk to SDDM itself – it
// emits loginRequested() and Main.qml owns the authentication state.
//
// phase: "login" | "auth" | "success" | "error"
FocusScope {
    id: panel

    property var theme
    property var strings
    property var audio
    property string phase: "login"
    property string message: ""          // detail text for error / hints
    property bool messageIsError: true

    readonly property alias userName: userField.text
    readonly property alias password: passwordField.text
    readonly property int sessionIndex: sessionBox.currentIndex
    readonly property bool busy: phase === "auth" || phase === "success"

    signal loginRequested(string user, string password, int sessionIndex)
    signal activity()

    implicitWidth: theme.px(460)
    implicitHeight: content.implicitHeight + theme.px(64)

    // ---- public helpers used by Main.qml ----------------------------------
    function focusInitial() {
        if (userField.text.length === 0)
            userField.input.forceActiveFocus()
        else
            passwordField.input.forceActiveFocus()
    }
    function clearPassword() {
        passwordField.text = ""
        passwordField.echoMode = TextInput.Password
    }
    function focusUser() { userField.input.forceActiveFocus() }
    function focusPassword() { passwordField.input.forceActiveFocus() }
    function submit() {
        if (!busy)
            loginRequested(userField.text.trim(), passwordField.text, sessionBox.currentIndex)
    }

    // ---- panel chrome ----------------------------------------------------
    Rectangle {
        anchors.fill: parent
        radius: panel.theme.px(4)
        color: panel.theme.alpha(panel.theme.panel, 0.72)
        border.width: 1
        border.color: panel.theme.alpha(panel.theme.line, 0.8)
    }

    // Industrial corner brackets.
    Repeater {
        model: 4
        Item {
            required property int index
            readonly property bool isRight: index % 2 === 1
            readonly property bool isBottom: index >= 2
            width: panel.theme.px(18)
            height: width
            x: isRight ? panel.width - width - panel.theme.px(6) : panel.theme.px(6)
            y: isBottom ? panel.height - height - panel.theme.px(6) : panel.theme.px(6)
            Rectangle {
                width: parent.width; height: 2
                y: parent.isBottom ? parent.height - 2 : 0
                color: panel.phase === "error" ? panel.theme.error : panel.theme.orange
            }
            Rectangle {
                width: 2; height: parent.height
                x: parent.isRight ? parent.width - 2 : 0
                color: panel.phase === "error" ? panel.theme.error : panel.theme.orange
            }
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: panel.theme.px(32)
        spacing: panel.theme.px(14)

        StatusHeader {
            id: header
            width: parent.width
        }

        ConsoleField {
            id: userField
            theme: panel.theme
            width: parent.width
            iconSource: Qt.resolvedUrl("../assets/icons/user.svg")
            placeholderText: panel.strings.tr("username")
            text: typeof userModel !== "undefined" && userModel.lastUser ? userModel.lastUser : ""
            enabled: !panel.busy
            error: panel.phase === "error"
            trailingIcon: panel.theme.showUserList && typeof userModel !== "undefined" && userModel.count > 0
                          ? Qt.resolvedUrl("../assets/icons/chevron-down.svg") : ""
            trailingToolTip: panel.strings.tr("selectUser")
            onTrailingClicked: userPopup.open()
            onAccepted: panel.focusPassword()
            onFocusedChanged: if (focused) panel.audio.play("ui_focus")
            input.onTextEdited: panel.activity()
        }

        Column {
            width: parent.width
            spacing: panel.theme.px(6)

            ConsoleField {
                id: passwordField
                theme: panel.theme
                width: parent.width
                iconSource: Qt.resolvedUrl("../assets/icons/lock.svg")
                placeholderText: panel.strings.tr("password")
                echoMode: TextInput.Password
                enabled: !panel.busy
                error: panel.phase === "error"
                trailingIcon: Qt.resolvedUrl(echoMode === TextInput.Password ? "../assets/icons/eye.svg"
                                                                             : "../assets/icons/eye-off.svg")
                trailingToolTip: panel.strings.tr("showPassword")
                onTrailingClicked: echoMode = (echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password)
                onAccepted: panel.submit()
                onFocusedChanged: if (focused) panel.audio.play("ui_focus")
                input.onTextEdited: panel.activity()
            }

            // Caps-lock hint (SDDM's keyboard model reports the LED state).
            Row {
                spacing: panel.theme.px(6)
                height: panel.theme.px(16)
                opacity: typeof keyboard !== "undefined" && keyboard.capsLock ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: panel.theme.fast } }
                Image {
                    width: panel.theme.px(14); height: width
                    sourceSize: Qt.size(width * 2, height * 2)
                    source: Qt.resolvedUrl("../assets/icons/caps.svg")
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: panel.strings.tr("capsLock")
                    color: panel.theme.orangeBright
                    font.family: panel.theme.font
                    font.pixelSize: panel.theme.px(12)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        LoginButton {
            id: loginButton
            width: parent.width
        }

        Item { width: 1; height: panel.theme.px(4) }

        // ---- session / keyboard layout ----
        Row {
            id: selectors
            width: parent.width
            spacing: panel.theme.px(14)

            readonly property bool hasLayouts: typeof keyboard !== "undefined" && keyboard.enabled
                                               && keyboard.layouts && keyboard.layouts.length > 1
            readonly property real colWidth: hasLayouts ? (width - spacing) / 2 : width

            Column {
                width: selectors.colWidth
                spacing: panel.theme.px(6)
                SelectorLabel { icon: "monitor.svg"; text: panel.strings.tr("session") }
                ConsoleComboBox {
                    id: sessionBox
                    theme: panel.theme
                    width: parent.width
                    enabled: !panel.busy
                    model: typeof sessionModel !== "undefined" ? sessionModel : []
                    textRole: "name"
                    currentIndex: typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                    onActivated: panel.audio.play("ui_click")
                }
            }

            Column {
                visible: selectors.hasLayouts
                width: selectors.colWidth
                spacing: panel.theme.px(6)
                SelectorLabel { icon: "keyboard.svg"; text: panel.strings.tr("layout") }
                ConsoleComboBox {
                    id: layoutBox
                    theme: panel.theme
                    width: parent.width
                    enabled: !panel.busy
                    model: selectors.hasLayouts ? keyboard.layouts : []
                    textRole: "longName"
                    currentIndex: selectors.hasLayouts ? keyboard.currentLayout : -1
                    onActivated: function(index) {
                        keyboard.currentLayout = index
                        panel.audio.play("ui_click")
                    }
                }
            }
        }
    }

    // ---- user list popup ---------------------------------------------------
    Popup {
        id: userPopup
        parent: userField
        y: userField.height + panel.theme.px(4)
        width: userField.width
        padding: 1
        implicitHeight: Math.min(userList.contentHeight + 2, panel.theme.px(240))
        onClosed: panel.focusInitial()

        background: Rectangle {
            color: panel.theme.panel
            border.color: panel.theme.line
            radius: panel.theme.px(3)
        }

        contentItem: ListView {
            id: userList
            clip: true
            model: typeof userModel !== "undefined" ? userModel : null
            keyNavigationEnabled: true
            focus: true
            ScrollIndicator.vertical: ScrollIndicator {}

            delegate: ItemDelegate {
                id: userEntry
                required property int index
                required property string name
                required property string realName
                width: ListView.view.width
                height: panel.theme.px(44)
                highlighted: ListView.isCurrentItem || hovered
                hoverEnabled: true

                contentItem: Item {
                    Column {
                        leftPadding: panel.theme.px(8)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: userEntry.realName.length > 0 ? userEntry.realName : userEntry.name
                            color: panel.theme.text
                            font.family: panel.theme.font
                            font.pixelSize: panel.theme.px(14)
                        }
                        Text {
                            visible: userEntry.realName.length > 0
                            text: userEntry.name
                            color: panel.theme.muted
                            font.family: panel.theme.mono
                            font.pixelSize: panel.theme.px(11)
                        }
                    }
                }
                background: Rectangle {
                    color: userEntry.highlighted ? panel.theme.alpha(panel.theme.orange, 0.16) : "transparent"
                }
                onClicked: {
                    userField.text = name
                    panel.audio.play("ui_click")
                    userPopup.close()
                    panel.focusPassword()
                }
            }
            Keys.onReturnPressed: currentItem && currentItem.clicked()
            Keys.onEnterPressed: currentItem && currentItem.clicked()
        }
    }

    // ---- inline helper components ------------------------------------------

    component SelectorLabel: Row {
        property string icon
        property alias text: label.text
        spacing: panel.theme.px(6)
        Image {
            width: panel.theme.px(15); height: width
            sourceSize: Qt.size(width * 2, height * 2)
            source: Qt.resolvedUrl("../assets/icons/" + parent.icon)
            opacity: 0.7
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: label
            color: panel.theme.muted
            font.family: panel.theme.font
            font.pixelSize: panel.theme.px(13)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Status slot with fixed height, so the layout never jumps.
    component StatusHeader: Item {
        implicitHeight: panel.theme.px(58)

        // Normal / authenticating.
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: panel.theme.px(6)
            opacity: panel.phase === "login" || panel.phase === "auth" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: panel.theme.fast } }

            Text {
                text: panel.strings.tr("panel.header")
                color: panel.theme.muted
                font.family: panel.theme.mono
                font.pixelSize: panel.theme.px(11)
                font.letterSpacing: panel.theme.px(2)
            }
            Row {
                spacing: panel.theme.px(8)
                Rectangle {
                    id: statusDot
                    width: panel.theme.px(7); height: width; radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: panel.message.length > 0 && !panel.messageIsError ? panel.theme.orangeBright
                         : panel.phase === "auth" ? panel.theme.blue : panel.theme.orange
                    SequentialAnimation on opacity {
                        running: panel.theme.animate && panel.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: panel.phase === "auth" ? 260 : 1100 }
                        NumberAnimation { to: 1.0; duration: panel.phase === "auth" ? 260 : 1100 }
                    }
                }
                Text {
                    text: panel.phase === "auth" ? panel.strings.tr("panel.auth")
                        : panel.message.length > 0 && !panel.messageIsError ? panel.message
                        : panel.strings.tr("panel.awaiting")
                    color: panel.theme.text
                    font.family: panel.theme.mono
                    font.pixelSize: panel.theme.px(13)
                    font.letterSpacing: panel.theme.px(1)
                }
            }
        }

        // Error banner.
        Rectangle {
            anchors.fill: parent
            radius: panel.theme.px(3)
            color: panel.theme.alpha(panel.theme.error, 0.12)
            border.color: panel.theme.alpha(panel.theme.error, 0.7)
            opacity: panel.phase === "error" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: panel.theme.fast } }

            Image {
                id: alertIcon
                anchors.left: parent.left
                anchors.leftMargin: panel.theme.px(14)
                anchors.verticalCenter: parent.verticalCenter
                width: panel.theme.px(22); height: width
                sourceSize: Qt.size(width * 2, height * 2)
                source: Qt.resolvedUrl("../assets/icons/alert.svg")
            }
            Column {
                anchors.left: alertIcon.right
                anchors.leftMargin: panel.theme.px(12)
                anchors.right: parent.right
                anchors.rightMargin: panel.theme.px(10)
                anchors.verticalCenter: parent.verticalCenter
                spacing: panel.theme.px(3)
                Text {
                    text: panel.strings.tr("panel.failed")
                    color: panel.theme.error
                    font.family: panel.theme.mono
                    font.pixelSize: panel.theme.px(13)
                    font.bold: true
                    font.letterSpacing: panel.theme.px(1)
                }
                Text {
                    width: parent.width
                    text: panel.message
                    color: Qt.lighter(panel.theme.error, 1.35)
                    font.family: panel.theme.font
                    font.pixelSize: panel.theme.px(12)
                    elide: Text.ElideRight
                }
            }
        }

        // Success banner.
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: panel.theme.px(12)
            opacity: panel.phase === "success" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: panel.theme.normal } }

            Rectangle {
                width: panel.theme.px(34); height: width; radius: width / 2
                color: "transparent"
                border.color: panel.theme.blue
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    anchors.centerIn: parent
                    width: panel.theme.px(20); height: width
                    sourceSize: Qt.size(width * 2, height * 2)
                    source: Qt.resolvedUrl("../assets/icons/check.svg")
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: panel.theme.px(3)
                Text {
                    text: panel.strings.tr("panel.success")
                    color: panel.theme.blue
                    font.family: panel.theme.mono
                    font.pixelSize: panel.theme.px(14)
                    font.bold: true
                    font.letterSpacing: panel.theme.px(1)
                }
                Text {
                    text: panel.strings.tr("success")
                    color: panel.theme.blueBright
                    font.family: panel.theme.font
                    font.pixelSize: panel.theme.px(12)
                }
            }
        }
    }

    component LoginButton: AbstractButton {
        id: button
        implicitHeight: panel.theme.px(48)
        hoverEnabled: true
        enabled: !panel.busy
        focusPolicy: Qt.StrongFocus
        onClicked: {
            panel.audio.play("ui_click")
            panel.submit()
        }
        Keys.onReturnPressed: clicked()
        Keys.onEnterPressed: clicked()

        readonly property color fill: panel.phase === "error" ? panel.theme.error
                                    : panel.phase === "success" ? panel.theme.blue
                                    : button.down ? Qt.darker(panel.theme.orange, 1.15)
                                    : button.hovered || button.activeFocus ? panel.theme.orangeBright
                                    : panel.theme.orange

        background: Rectangle {
            radius: panel.theme.px(3)
            color: panel.phase === "auth" ? panel.theme.alpha(panel.theme.orange, 0.35) : button.fill
            Behavior on color { ColorAnimation { duration: panel.theme.fast } }

            // Focus ring.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -panel.theme.px(3)
                radius: panel.theme.px(5)
                color: "transparent"
                border.width: 1
                border.color: panel.theme.orangeBright
                visible: button.activeFocus
            }

            // Indeterminate progress sweep while authenticating.
            Item {
                anchors.fill: parent
                clip: true
                visible: panel.phase === "auth"
                Rectangle {
                    id: sweepBar
                    width: parent.width * 0.3
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: panel.theme.alpha(panel.theme.orangeBright, 0.8) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                    NumberAnimation on x {
                        running: panel.phase === "auth"
                        from: -sweepBar.width; to: sweepBar.parent.width
                        duration: 1100
                        loops: Animation.Infinite
                    }
                }
            }
        }

        contentItem: Text {
            text: panel.phase === "auth" ? panel.strings.tr("loggingIn") : panel.strings.tr("login")
            color: panel.phase === "auth" ? panel.theme.text : panel.theme.buttonText
            font.family: panel.theme.font
            font.pixelSize: panel.theme.px(15)
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Slight lift on hover.
        scale: button.down ? 0.985 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
    }
}
