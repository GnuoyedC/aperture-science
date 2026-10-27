pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic

// Console-styled drop-down. Works with SDDM's QAbstractListModels
// (sessionModel, role "name") and with plain object lists (keyboard.layouts,
// property "longName") – see itemText().
ComboBox {
    id: box

    property var theme

    implicitHeight: theme.px(42)
    font.family: theme.font
    font.pixelSize: theme.px(14)
    hoverEnabled: true

    // Resolves the label of one entry for either kind of model.
    function itemText(modelObj, modelDataObj) {
        if (!textRole)
            return String(modelDataObj)
        if (modelObj && modelObj[textRole] !== undefined)
            return String(modelObj[textRole])
        if (modelDataObj && modelDataObj[textRole] !== undefined)
            return String(modelDataObj[textRole])
        return ""
    }

    background: Rectangle {
        radius: box.theme.px(3)
        color: box.theme.alpha(box.theme.field, 0.82)
        border.width: 1
        border.color: box.visualFocus || box.popup.visible ? box.theme.orange
                    : box.hovered ? Qt.lighter(box.theme.line, 1.5) : box.theme.line
        Behavior on border.color { ColorAnimation { duration: box.theme.fast } }
    }

    contentItem: Text {
        leftPadding: box.theme.px(14)
        rightPadding: box.indicator.width + box.theme.px(8)
        text: box.displayText
        font: box.font
        color: box.theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Image {
        x: box.width - width - box.theme.px(12)
        y: (box.height - height) / 2
        width: box.theme.px(16)
        height: width
        sourceSize: Qt.size(width * 2, height * 2)
        source: Qt.resolvedUrl("../assets/icons/chevron-down.svg")
        opacity: box.hovered ? 1 : 0.65
        rotation: box.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: box.theme.fast } }
    }

    delegate: ItemDelegate {
        id: entry
        required property int index
        required property var model
        property var modelData: model.modelData

        width: ListView.view ? ListView.view.width : box.width
        height: box.theme.px(36)
        highlighted: box.highlightedIndex === index
        hoverEnabled: true

        contentItem: Text {
            leftPadding: box.theme.px(6)
            text: box.itemText(entry.model, entry.modelData)
            color: entry.index === box.currentIndex ? box.theme.orangeBright : box.theme.text
            font: box.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: entry.highlighted ? box.theme.alpha(box.theme.orange, 0.16) : "transparent"
            Rectangle {
                visible: entry.highlighted
                width: box.theme.px(2)
                height: parent.height
                color: box.theme.orange
            }
        }
    }

    popup: Popup {
        y: box.height + box.theme.px(4)
        width: box.width
        implicitHeight: Math.min(contentItem.implicitHeight + 2, box.theme.px(260))
        padding: 1

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: box.theme.fast }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: box.theme.fast }
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: box.popup.visible ? box.delegateModel : null
            currentIndex: box.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: box.theme.panel
            border.color: box.theme.line
            radius: box.theme.px(3)
        }
    }
}
