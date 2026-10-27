import QtQuick
import QtQuick.Layouts

// One labelled line of a status panel: fixed-width mono label on the left,
// free content (children) on the right.
RowLayout {
    id: row

    property Tokens tk
    property string label: ""
    property real labelWidth: 60
    default property alias content: body.data

    spacing: 10

    MonoLabel {
        tk: row.tk
        text: row.label
        Layout.preferredWidth: row.labelWidth
        Layout.minimumWidth: row.labelWidth
        Layout.alignment: Qt.AlignVCenter
    }
    RowLayout {
        id: body
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: row.spacing
    }
}
