import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.iconthemes as KIconThemes
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: page

    readonly property string defaultIcon: "aperture-os"

    property string cfg_icon: Plasmoid.configuration.icon
    property alias cfg_showFavorites: showFavorites.checked
    property alias cfg_showCategories: showCategories.checked
    property alias cfg_maxResults: maxResults.value
    property alias cfg_favoritesClientId: favoritesClientId.text
    property alias cfg_reduceMotion: reduceMotion.checked

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Icon:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                id: iconButton
                implicitWidth: Kirigami.Units.iconSizes.large + Kirigami.Units.largeSpacing * 2
                implicitHeight: implicitWidth
                Accessible.name: i18n("Choose icon")
                QQC2.ToolTip.text: page.cfg_icon
                QQC2.ToolTip.visible: hovered
                onClicked: iconDialog.open()

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    source: page.cfg_icon || page.defaultIcon
                }
            }
            QQC2.Button {
                text: i18n("Default")
                icon.name: "edit-undo"
                enabled: page.cfg_icon !== page.defaultIcon
                onClicked: page.cfg_icon = page.defaultIcon
            }
            KIconThemes.IconDialog {
                id: iconDialog
                onAccepted: page.cfg_icon = iconName || page.defaultIcon
            }
        }

        QQC2.CheckBox {
            id: showFavorites
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("Favorites")
        }
        QQC2.CheckBox {
            id: showCategories
            text: i18n("Categories")
        }

        QQC2.SpinBox {
            id: maxResults
            Kirigami.FormData.label: i18n("Search results (max.):")
            from: 3
            to: 50
        }

        QQC2.TextField {
            id: favoritesClientId
            Kirigami.FormData.label: i18n("Favorites order from:")
            placeholderText: i18n("own instance")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        }

        QQC2.CheckBox {
            id: reduceMotion
            Kirigami.FormData.label: i18n("Motion:")
            text: i18n("Reduce animations")
        }
    }
}
