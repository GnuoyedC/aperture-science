import QtQuick

// Small uppercase technical label (accent only).
Text {
    property Tokens tk
    property bool strong: false

    color: tk ? (strong ? tk.text : tk.textMuted) : "gray"
    font.family: tk ? tk.monoFamily : "monospace"
    font.pointSize: tk ? tk.labelSize : 8
    font.letterSpacing: 1.2
    font.capitalization: Font.AllUppercase
    font.weight: strong ? Font.Medium : Font.Normal
    elide: Text.ElideRight
    textFormat: Text.PlainText
}
