import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_maxItems: itemsSpin.value
    property alias cfg_showLowUrgency: lowCheck.checked
    property alias cfg_keywordHeuristics: heuristicsCheck.checked
    property alias cfg_reduceMotion: motionCheck.checked

    property int cfg_maxItemsDefault
    property bool cfg_showLowUrgencyDefault
    property bool cfg_keywordHeuristicsDefault
    property bool cfg_reduceMotionDefault

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: itemsSpin
            Kirigami.FormData.label: i18n("Number of notices:")
            from: 1
            to: 3
        }
        QQC2.CheckBox {
            id: lowCheck
            Kirigami.FormData.label: i18n("Filter:")
            text: i18n("Also show low-priority notifications")
        }
        QQC2.CheckBox {
            id: heuristicsCheck
            Kirigami.FormData.label: i18n("Colouring:")
            text: i18n("Detect error/warning/success from keywords")
        }
        QQC2.CheckBox {
            id: motionCheck
            Kirigami.FormData.label: i18n("Motion:")
            text: i18n("Reduce animations (no pulsing for critical notices)")
        }
    }
}
