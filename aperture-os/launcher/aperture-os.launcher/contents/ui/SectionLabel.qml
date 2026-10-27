import QtQuick
import QtQuick.Layouts

// Section caption: "◉ FAVORITEN ........................ 06"
RowLayout {
    id: section

    property Tokens tk
    property string glyph: ""
    property string text: ""
    property string info: ""

    spacing: 6

    MonoLabel {
        visible: section.glyph.length > 0
        tk: section.tk
        text: section.glyph
        color: section.tk ? section.tk.orange : "orange"
    }
    MonoLabel {
        tk: section.tk
        text: section.text
        Layout.alignment: Qt.AlignVCenter
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 1
        color: section.tk ? section.tk.alpha(section.tk.border, 0.6) : "gray"
    }
    MonoLabel {
        visible: section.info.length > 0
        tk: section.tk
        text: section.info
        color: section.tk ? section.tk.textDisabled : "gray"
    }
}
