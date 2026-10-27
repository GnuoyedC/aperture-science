pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic

// Modal "System" console for power actions. Opened with open(action) to
// pre-select an entry; Enter confirms, Escape / "Abbrechen" closes.
// Only actions that SDDM reports as available are listed.
Popup {
    id: menu

    property var theme
    property var strings
    property var audio

    signal actionTriggered(string action)

    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: theme.px(380)
    padding: theme.px(22)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    readonly property var actions: {
        const has = typeof sddm !== "undefined"
        const list = []
        if (has && sddm.canPowerOff)
            list.push({ id: "powerOff", icon: "power.svg" })
        if (has && sddm.canReboot)
            list.push({ id: "reboot", icon: "reboot.svg" })
        if (has && sddm.canSuspend)
            list.push({ id: "suspend", icon: "suspend.svg" })
        if (has && sddm.canHibernate)
            list.push({ id: "hibernate", icon: "hibernate.svg" })
        return list
    }

    function openFor(actionId) {
        let idx = 0
        for (let i = 0; i < actions.length; ++i)
            if (actions[i].id === actionId)
                idx = i
        entries.currentIndex = idx
        open()
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.55)
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 140 }
    }

    onOpened: entries.forceActiveFocus()

    background: Rectangle {
        color: menu.theme.alpha(menu.theme.panel, 0.95)
        border.color: menu.theme.line
        radius: menu.theme.px(4)
        Rectangle {
            width: parent.width; height: 2
            color: menu.theme.orange
        }
    }

    contentItem: Column {
        spacing: menu.theme.px(10)

        Row {
            spacing: menu.theme.px(10)
            Text {
                text: menu.strings.tr("system")
                color: menu.theme.text
                font.family: menu.theme.font
                font.pixelSize: menu.theme.px(17)
                font.weight: Font.DemiBold
            }
            Text {
                anchors.baseline: parent.children[0].baseline
                text: "// " + menu.theme.chamberId.toUpperCase()
                color: menu.theme.muted
                font.family: menu.theme.mono
                font.pixelSize: menu.theme.px(11)
            }
        }

        Rectangle { width: parent.width; height: 1; color: menu.theme.line }

        ListView {
            id: entries
            width: parent.width
            height: contentHeight
            interactive: false
            keyNavigationEnabled: true
            model: menu.actions

            Keys.onReturnPressed: currentItem && currentItem.trigger()
            Keys.onEnterPressed: currentItem && currentItem.trigger()

            delegate: AbstractButton {
                id: entry
                required property var modelData
                required property int index
                width: ListView.view.width
                height: menu.theme.px(58)
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                readonly property bool current: ListView.isCurrentItem

                function trigger() {
                    menu.audio.play("ui_click")
                    menu.close()
                    menu.actionTriggered(modelData.id)
                }
                onClicked: trigger()
                onHoveredChanged: if (hovered) entries.currentIndex = index

                background: Rectangle {
                    color: entry.current ? menu.theme.alpha(menu.theme.orange, 0.12) : "transparent"
                    radius: menu.theme.px(3)
                    Rectangle {
                        visible: entry.current
                        width: 2; height: parent.height
                        color: menu.theme.orange
                    }
                }
                contentItem: Row {
                    leftPadding: menu.theme.px(12)
                    spacing: menu.theme.px(16)
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: menu.theme.px(24); height: width
                        sourceSize: Qt.size(width * 2, height * 2)
                        source: Qt.resolvedUrl("../assets/icons/" + entry.modelData.icon)
                        opacity: entry.current ? 1 : 0.7
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: menu.theme.px(2)
                        Text {
                            text: menu.strings.tr(entry.modelData.id)
                            color: menu.theme.text
                            font.family: menu.theme.font
                            font.pixelSize: menu.theme.px(15)
                        }
                        Text {
                            text: menu.strings.tr(entry.modelData.id + "Hint")
                            color: entry.current ? menu.theme.orangeBright : menu.theme.muted
                            font.family: menu.theme.font
                            font.pixelSize: menu.theme.px(12)
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: menu.theme.line }

        AbstractButton {
            id: cancel
            anchors.right: parent.right
            height: menu.theme.px(36)
            width: cancelRow.implicitWidth + menu.theme.px(24)
            hoverEnabled: true
            onClicked: {
                menu.audio.play("ui_click")
                menu.close()
            }
            background: Rectangle {
                color: cancel.hovered ? menu.theme.alpha(menu.theme.text, 0.08) : "transparent"
                radius: menu.theme.px(3)
            }
            contentItem: Item {
                Row {
                    id: cancelRow
                    anchors.centerIn: parent
                    spacing: menu.theme.px(8)
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: menu.theme.px(16); height: width
                        sourceSize: Qt.size(width * 2, height * 2)
                        source: Qt.resolvedUrl("../assets/icons/close.svg")
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: menu.strings.tr("cancel")
                        color: menu.theme.text
                        font.family: menu.theme.font
                        font.pixelSize: menu.theme.px(14)
                    }
                }
            }
        }
    }
}
