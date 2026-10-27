import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_updateInterval: intervalSpin.value
    property alias cfg_diskSensor: diskField.text
    property alias cfg_reduceMotion: motionCheck.checked

    property alias cfg_panelLed: panelLedCheck.checked
    property alias cfg_panelCpu: panelCpuCheck.checked
    property alias cfg_panelRam: panelRamCheck.checked
    property alias cfg_panelDisk: panelDiskCheck.checked
    property alias cfg_panelNetwork: panelNetworkCheck.checked
    property alias cfg_clickToExpand: clickCheck.checked

    property alias cfg_showCpu: cpuCheck.checked
    property alias cfg_showRam: ramCheck.checked
    property alias cfg_showDisk: diskCheck.checked
    property alias cfg_showNetwork: networkCheck.checked

    property int cfg_updateIntervalDefault
    property string cfg_diskSensorDefault
    property bool cfg_reduceMotionDefault
    property bool cfg_panelLedDefault
    property bool cfg_panelCpuDefault
    property bool cfg_panelRamDefault
    property bool cfg_panelDiskDefault
    property bool cfg_panelNetworkDefault
    property bool cfg_clickToExpandDefault
    property bool cfg_showCpuDefault
    property bool cfg_showRamDefault
    property bool cfg_showDiskDefault
    property bool cfg_showNetworkDefault

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Update interval (seconds):")
            from: 2
            to: 30
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Task bar")
        }
        QQC2.CheckBox {
            id: panelCpuCheck
            Kirigami.FormData.label: i18n("Show in the task bar:")
            text: i18n("CPU usage")
        }
        QQC2.CheckBox {
            id: panelRamCheck
            text: i18n("RAM usage")
        }
        QQC2.CheckBox {
            id: panelDiskCheck
            text: i18n("Disk usage")
        }
        QQC2.CheckBox {
            id: panelNetworkCheck
            text: i18n("Network download/upload rate")
        }
        QQC2.CheckBox {
            id: panelLedCheck
            Kirigami.FormData.label: i18n("Status:")
            text: i18n("LED (worst of CPU, RAM, disk)")
        }
        QQC2.CheckBox {
            id: clickCheck
            Kirigami.FormData.label: i18n("Click:")
            text: i18n("Open the details popup")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Popup")
        }
        QQC2.CheckBox {
            id: cpuCheck
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("CPU")
        }
        QQC2.CheckBox {
            id: ramCheck
            text: i18n("RAM")
        }
        QQC2.CheckBox {
            id: diskCheck
            text: i18n("Disk")
        }
        QQC2.CheckBox {
            id: networkCheck
            text: i18n("Network with history graph")
        }
        QQC2.TextField {
            id: diskField
            Kirigami.FormData.label: i18n("Disk sensor:")
            placeholderText: i18n("automatic (root file system /)")
        }
        QQC2.Label {
            text: i18n("e.g. disk/all/usedPercent – IDs: »kstatsviewer --list«")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
        QQC2.CheckBox {
            id: motionCheck
            Kirigami.FormData.label: i18n("Motion:")
            text: i18n("Reduce animations")
        }
    }
}
