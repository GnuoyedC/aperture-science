pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

// Favourite tile: application icon with a one-line caption below.
Item {
    id: tile

    required property int index
    required property var model
    property Tokens tk

    readonly property GridView view: GridView.view
    readonly property bool isCurrent: GridView.isCurrentItem
    readonly property bool hovered: mouse.containsMouse && launcher.hoverActive
    readonly property string label: model.display ?? ""

    signal activated(int index)
    signal contextMenuRequested(Item item, int index, real x, real y)

    width: view ? view.cellWidth : 80
    height: view ? view.cellHeight : 70

    Accessible.role: Accessible.ListItem
    Accessible.name: label

    PlasmaExtras.Highlight {
        anchors.fill: parent
        anchors.margins: 1
        hovered: true
        pressed: mouse.pressed
        active: tile.hovered || (tile.view && tile.view.activeFocus)
        visible: tile.hovered || (tile.isCurrent && tile.view && tile.view.activeFocus)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.smallSpacing * 2
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            source: tile.model.decoration ?? ""
            fallback: "application-x-executable"
            animated: false
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: tile.label
            color: tile.tk ? (tile.isCurrent && tile.view && tile.view.activeFocus || tile.hovered ? tile.tk.text : tile.tk.textMuted) : "white"
            font.family: tile.tk ? tile.tk.uiFamily : "sans-serif"
            font.pointSize: tile.tk ? tile.tk.uiSize - 1 : 9
            elide: Text.ElideRight
            maximumLineCount: 1
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: mouseEvent => {
            if (launcher.hoverMoved(mouse, mouseEvent.x, mouseEvent.y) && tile.view)
                tile.view.currentIndex = tile.index
        }
        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.RightButton)
                tile.contextMenuRequested(tile, tile.index, mouseEvent.x, mouseEvent.y)
            else
                tile.activated(tile.index)
        }
    }
}
