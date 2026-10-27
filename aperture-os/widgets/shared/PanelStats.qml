import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Compact (task bar) representation: optional LED followed by any number of
// short stat strings ("CPU  12%", "CH01" …). Clicking only emits `activated`
// when `clickable` is on; what the popup shows is up to the plasmoid.
MouseArea {
    id: panel

    property Tokens tk
    property var items: []
    property bool showLed: true
    property color ledColor: tk ? tk.blue : "white"
    property bool breathing: false
    property bool reduceMotion: false
    property bool clickable: true
    property bool expanded: false
    property bool vertical: false

    signal activated()

    readonly property real pad: Kirigami.Units.smallSpacing * 2
    readonly property bool empty: items.length === 0 && !showLed

    Layout.minimumWidth: vertical ? 0 : stats.implicitWidth + pad
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: vertical ? stats.implicitHeight + pad : 0
    Layout.preferredHeight: Layout.minimumHeight

    hoverEnabled: true
    cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: if (clickable) activated()

    Grid {
        id: stats
        anchors.centerIn: parent
        flow: panel.vertical ? Grid.TopToBottom : Grid.LeftToRight
        rows: panel.vertical ? 100 : 1
        columns: panel.vertical ? 1 : 100
        spacing: panel.vertical ? 4 : 10
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Led {
            visible: panel.showLed
            tk: panel.tk
            color: panel.ledColor
            breathing: panel.breathing
            reduceMotion: panel.reduceMotion
        }
        Repeater {
            model: panel.items
            delegate: MonoLabel {
                required property string modelData
                tk: panel.tk
                strong: panel.containsMouse || panel.expanded
                text: modelData
            }
        }
    }

    // orange underline while the popup is open
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: panel.vertical ? parent.width : stats.implicitWidth
        height: panel.tk ? panel.tk.accentWidth : 2
        color: panel.tk ? panel.tk.orange : "orange"
        visible: panel.expanded
    }
}
