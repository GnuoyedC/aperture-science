import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_Animate: animate.checked
    property alias cfg_SceneGlows: glows.checked
    property alias cfg_Intensity: intensity.value
    property alias cfg_FrameRate: fps.value
    property alias cfg_Mirror: mirror.checked
    property alias cfg_Zoom: zoom.value
    property alias cfg_FocusX: focusX.value
    property alias cfg_FocusY: focusY.value
    property string cfg_Image
    property string cfg_Scene

    readonly property var motifs: [
        { id: "chamber", name: i18n("Test chamber (built-in)") },
        { id: "ApertureCoreMaintenanceHall", name: i18n("Core maintenance bay") },
        { id: "ApertureResearchComplex", name: i18n("Research complex at night") },
        { id: "ApertureLaboratories", name: i18n("Laboratories atrium") },
        { id: "AperturePortalChamber", name: i18n("Test chamber with portals") },
        { id: "ApertureOvergrown", name: i18n("Overgrown test chamber") }
    ]

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Motif:")
        model: page.motifs
        textRole: "name"
        valueRole: "id"
        currentIndex: Math.max(0, page.motifs.findIndex(m => m.id === page.cfg_Scene))
        onActivated: page.cfg_Scene = currentValue
    }

    QQC2.CheckBox {
        id: animate
        Kirigami.FormData.label: i18n("Ambience:")
        text: i18n("Animate (core pulse, portal glow, light drift)")
    }
    QQC2.CheckBox {
        id: glows
        text: i18n("Core / portal glows (not for own images)")
    }
    QQC2.Slider {
        id: intensity
        Kirigami.FormData.label: i18n("Intensity:")
        from: 0; to: 1; stepSize: 0.05
    }
    QQC2.SpinBox {
        id: fps
        Kirigami.FormData.label: i18n("Updates per second:")
        from: 1; to: 30
    }
    QQC2.CheckBox {
        id: mirror
        Kirigami.FormData.label: i18n("Framing:")
        text: i18n("Mirror horizontally (lettering is mirrored too)")
    }
    QQC2.Slider {
        id: zoom
        Kirigami.FormData.label: i18n("Zoom:")
        from: 1; to: 2; stepSize: 0.05
    }
    QQC2.Slider {
        id: focusX
        Kirigami.FormData.label: i18n("Crop left ↔ right:")
        from: 0; to: 1; stepSize: 0.05
    }
    QQC2.Slider {
        id: focusY
        Kirigami.FormData.label: i18n("Crop top ↕ bottom:")
        from: 0; to: 1; stepSize: 0.05
    }
    Row {
        Kirigami.FormData.label: i18n("Own image:")
        spacing: Kirigami.Units.smallSpacing
        QQC2.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: page.cfg_Image.length ? page.cfg_Image : i18n("Motif above")
            elide: Text.ElideMiddle
            width: Kirigami.Units.gridUnit * 14
        }
        QQC2.Button {
            text: i18n("Choose…")
            onClicked: picker.open()
        }
        QQC2.Button {
            text: i18n("Reset")
            enabled: page.cfg_Image.length > 0
            onClicked: page.cfg_Image = ""
        }
    }
    FileDialog {
        id: picker
        nameFilters: [i18n("Images (*.jpg *.jpeg *.png *.webp)")]
        onAccepted: page.cfg_Image = selectedFile.toString().replace(/^file:\/\//, "")
    }
}
