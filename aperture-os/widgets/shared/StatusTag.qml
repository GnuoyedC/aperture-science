import QtQuick

// LED + status word. Status is never colour-only: the word carries it too.
Row {
    id: tag

    property Tokens tk
    property color color: tk ? tk.blue : "white"
    property string text: ""
    property bool breathing: false
    property bool reduceMotion: false

    spacing: 6

    Led {
        anchors.verticalCenter: parent.verticalCenter
        tk: tag.tk
        color: tag.color
        breathing: tag.breathing
        reduceMotion: tag.reduceMotion
    }
    MonoLabel {
        anchors.verticalCenter: parent.verticalCenter
        tk: tag.tk
        text: tag.text
        color: tag.color
        font.weight: Font.Medium
    }
}
