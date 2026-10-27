pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

// One row in a list (category, application or search result).
// Hover/focus use the Plasma Style's viewitem (orange left signal bar).
Item {
    id: row

    required property int index
    required property var model
    property Tokens tk
    // "category" shows a chevron, "result" shows the description below
    property string kind: "app"
    property bool showCurrent: false

    readonly property ListView view: ListView.view
    readonly property bool isCurrent: ListView.isCurrentItem
    readonly property bool hovered: mouse.containsMouse && launcher.hoverActive
    readonly property string label: model.display ?? ""
    readonly property string description: (model.description ?? "") !== label ? (model.description ?? "") : ""

    signal activated(int index)
    signal contextMenuRequested(Item item, int index, real x, real y)

    width: view ? view.width - view.leftMargin - view.rightMargin : implicitWidth
    implicitHeight: kind === "result" && description.length > 0
        ? Math.round(Kirigami.Units.gridUnit * 2.3)
        : Math.round(Kirigami.Units.gridUnit * 1.75)

    Accessible.role: Accessible.ListItem
    Accessible.name: label
    Accessible.description: description

    PlasmaExtras.Highlight {
        anchors.fill: parent
        hovered: true
        pressed: mouse.pressed
        active: row.hovered || (row.view && row.view.activeFocus)
        visible: row.hovered || (row.isCurrent && (row.showCurrent || (row.view && row.view.activeFocus)))
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2 + 2
        anchors.rightMargin: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing * 2

        Kirigami.Icon {
            Layout.preferredWidth: row.kind === "result" && row.description.length > 0
                ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            source: row.model.decoration ?? ""
            fallback: "application-x-executable"
            animated: false
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.label
                color: row.tk ? row.tk.text : "white"
                font.family: row.tk ? row.tk.uiFamily : "sans-serif"
                font.pointSize: row.tk ? row.tk.uiSize : 10
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            Text {
                Layout.fillWidth: true
                visible: row.kind === "result" && row.description.length > 0
                text: row.description
                color: row.tk ? row.tk.textMuted : "gray"
                font.family: row.tk ? row.tk.uiFamily : "sans-serif"
                font.pointSize: row.tk ? row.tk.uiSize - 1.5 : 8.5
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }

        Text {
            visible: row.kind === "app" && row.description.length > 0
            Layout.maximumWidth: row.width * 0.4
            text: row.description
            color: row.tk ? row.tk.textDisabled : "gray"
            font.family: row.tk ? row.tk.uiFamily : "sans-serif"
            font.pointSize: row.tk ? row.tk.uiSize - 1.5 : 8.5
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        MonoLabel {
            visible: row.kind === "category" || (row.model.hasChildren ?? false)
            tk: row.tk
            text: "›"
            font.pointSize: row.tk ? row.tk.uiSize + 1 : 11
            color: (row.isCurrent && row.view && row.view.activeFocus) || row.hovered ? (row.tk ? row.tk.orange : "orange") : (row.tk ? row.tk.textDisabled : "gray")
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: mouseEvent => {
            if (launcher.hoverMoved(mouse, mouseEvent.x, mouseEvent.y) && row.view)
                row.view.currentIndex = row.index
        }
        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.RightButton)
                row.contextMenuRequested(row, row.index, mouseEvent.x, mouseEvent.y)
            else
                row.activated(row.index)
        }
    }
}
