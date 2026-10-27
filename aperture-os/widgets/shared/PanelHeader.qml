import QtQuick
import QtQuick.Layouts

// Widget title line: emblem, title, right aligned technical subtitle and a
// divider with a short orange accent.
ColumnLayout {
    id: header

    property Tokens tk
    property string title: ""
    property string subtitle: ""
    property bool showLogo: true
    property string glyph: ""

    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 7

        Image {
            visible: header.showLogo && header.glyph.length === 0
            Layout.preferredWidth: 13
            Layout.preferredHeight: 13
            Layout.alignment: Qt.AlignVCenter
            source: Qt.resolvedUrl("../images/aperture-logo.svg")
            sourceSize: Qt.size(26, 26)
            opacity: 0.85
            smooth: true
        }
        MonoLabel {
            visible: header.glyph.length > 0
            tk: header.tk
            text: header.glyph
            color: header.tk ? header.tk.orange : "orange"
            font.pointSize: header.tk ? header.tk.valueSize : 10
            Layout.alignment: Qt.AlignVCenter
        }
        MonoLabel {
            tk: header.tk
            strong: true
            text: header.title
            // display face (Barlow Semi Condensed): signage-like titles
            font.family: header.tk ? header.tk.displayFamily : "sans-serif"
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            font.pointSize: header.tk ? header.tk.labelSize + 3 : 11
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
        }
        MonoLabel {
            tk: header.tk
            visible: text.length > 0
            text: header.subtitle
            color: header.tk ? header.tk.textDisabled : "gray"
            Layout.alignment: Qt.AlignVCenter
        }
    }
    Divider {
        tk: header.tk
        accent: true
        Layout.fillWidth: true
    }
}
