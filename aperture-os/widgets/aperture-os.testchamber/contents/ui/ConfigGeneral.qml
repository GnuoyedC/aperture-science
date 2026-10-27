import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_chamberNumber: chamberSpin.value
    property alias cfg_tempWarning: tempSpin.value
    property alias cfg_showCore: coreCheck.checked
    property alias cfg_showPortal: portalCheck.checked
    property alias cfg_showPower: powerCheck.checked
    property alias cfg_showCpuTemp: cpuTempCheck.checked
    property alias cfg_showCpuLoad: cpuLoadCheck.checked
    property alias cfg_showLoadAverage: loadAvgCheck.checked
    property alias cfg_showGpu: gpuCheck.checked
    property alias cfg_showFan: fanCheck.checked
    property alias cfg_showMemory: memoryCheck.checked
    property alias cfg_showSwap: swapCheck.checked
    property alias cfg_showDisk: diskCheck.checked
    property alias cfg_showNetwork: networkCheck.checked
    property alias cfg_showUptime: uptimeCheck.checked
    property alias cfg_showSession: sessionCheck.checked
    property alias cfg_showHost: hostCheck.checked
    property alias cfg_compactLayout: compactCheck.checked
    property alias cfg_reduceMotion: motionCheck.checked
    property alias cfg_panelLabel: labelPanel.checked
    property alias cfg_panelCpuTemp: cpuTempPanel.checked
    property alias cfg_panelCpuLoad: cpuLoadPanel.checked
    property alias cfg_panelMemory: memoryPanel.checked
    property alias cfg_panelSwap: swapPanel.checked
    property alias cfg_panelDisk: diskPanel.checked
    property alias cfg_panelGpu: gpuPanel.checked
    property alias cfg_panelFan: fanPanel.checked
    property alias cfg_panelPower: powerPanel.checked
    property alias cfg_panelNetwork: networkPanel.checked
    property alias cfg_panelUptime: uptimePanel.checked
    property alias cfg_panelLed: panelLedCheck.checked
    property alias cfg_clickToExpand: clickCheck.checked

    property int cfg_chamberNumberDefault
    property int cfg_tempWarningDefault
    property bool cfg_showCoreDefault
    property bool cfg_showPortalDefault
    property bool cfg_showPowerDefault
    property bool cfg_showCpuTempDefault
    property bool cfg_showCpuLoadDefault
    property bool cfg_showLoadAverageDefault
    property bool cfg_showGpuDefault
    property bool cfg_showFanDefault
    property bool cfg_showMemoryDefault
    property bool cfg_showSwapDefault
    property bool cfg_showDiskDefault
    property bool cfg_showNetworkDefault
    property bool cfg_showUptimeDefault
    property bool cfg_showSessionDefault
    property bool cfg_showHostDefault
    property bool cfg_compactLayoutDefault
    property bool cfg_reduceMotionDefault
    property bool cfg_panelLabelDefault
    property bool cfg_panelCpuTempDefault
    property bool cfg_panelCpuLoadDefault
    property bool cfg_panelMemoryDefault
    property bool cfg_panelSwapDefault
    property bool cfg_panelDiskDefault
    property bool cfg_panelGpuDefault
    property bool cfg_panelFanDefault
    property bool cfg_panelPowerDefault
    property bool cfg_panelNetworkDefault
    property bool cfg_panelUptimeDefault
    property bool cfg_panelLedDefault
    property bool cfg_clickToExpandDefault

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: chamberSpin
            Kirigami.FormData.label: i18n("Chamber number:")
            from: 0
            to: 99
        }
        QQC2.SpinBox {
            id: tempSpin
            Kirigami.FormData.label: i18n("Temperature warning from (°C):")
            from: 40
            to: 110
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Task bar")
        }
        QQC2.CheckBox {
            id: labelPanel
            Kirigami.FormData.label: i18n("Show in the task bar:")
            text: i18n("CH01 – chamber number")
        }
        QQC2.CheckBox {
            id: cpuTempPanel
            text: i18n("CPU temperature")
        }
        QQC2.CheckBox {
            id: cpuLoadPanel
            text: i18n("CPU usage")
        }
        QQC2.CheckBox {
            id: memoryPanel
            text: i18n("Memory usage")
        }
        QQC2.CheckBox {
            id: swapPanel
            text: i18n("Swap usage")
        }
        QQC2.CheckBox {
            id: diskPanel
            text: i18n("Disk usage (root file system)")
        }
        QQC2.CheckBox {
            id: gpuPanel
            text: i18n("GPU usage")
        }
        QQC2.CheckBox {
            id: fanPanel
            text: i18n("Fan speed")
        }
        QQC2.CheckBox {
            id: powerPanel
            text: i18n("Battery level")
        }
        QQC2.CheckBox {
            id: networkPanel
            text: i18n("Download/upload rate")
        }
        QQC2.CheckBox {
            id: uptimePanel
            text: i18n("Uptime")
        }
        QQC2.CheckBox {
            id: panelLedCheck
            Kirigami.FormData.label: i18n("Status:")
            text: i18n("LED (follows the CPU temperature)")
        }
        QQC2.CheckBox {
            id: clickCheck
            Kirigami.FormData.label: i18n("Click:")
            text: i18n("Open the details popup")
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18n("Stats without a sensor on this computer are skipped. Independent of the popup rows below.")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Popup rows")
        }

        QQC2.CheckBox {
            id: coreCheck
            Kirigami.FormData.label: i18n("Status:")
            text: i18n("CORE – core status (follows the CPU temperature)")
        }
        QQC2.CheckBox {
            id: portalCheck
            text: i18n("PORTAL – portal status (decoration)")
        }
        QQC2.CheckBox {
            id: powerCheck
            text: i18n("POWER – battery level")
        }

        QQC2.CheckBox {
            id: cpuTempCheck
            Kirigami.FormData.label: i18n("Processor:")
            text: i18n("CPU TEMP – temperature")
        }
        QQC2.CheckBox {
            id: cpuLoadCheck
            text: i18n("CPU LOAD – usage")
        }
        QQC2.CheckBox {
            id: loadAvgCheck
            text: i18n("LOAD AVG – load average 1/5/15 min")
        }

        QQC2.CheckBox {
            id: gpuCheck
            Kirigami.FormData.label: i18n("Hardware:")
            text: i18n("GPU – usage and temperature")
        }
        QQC2.CheckBox {
            id: fanCheck
            text: i18n("FAN – fan speed")
        }

        QQC2.CheckBox {
            id: memoryCheck
            Kirigami.FormData.label: i18n("Memory:")
            text: i18n("MEMORY – physical memory")
        }
        QQC2.CheckBox {
            id: swapCheck
            text: i18n("SWAP – swap space")
        }
        QQC2.CheckBox {
            id: diskCheck
            text: i18n("DISK / – root file system usage")
        }

        QQC2.CheckBox {
            id: networkCheck
            Kirigami.FormData.label: i18n("Network:")
            text: i18n("NETWORK – download/upload rate")
        }

        QQC2.CheckBox {
            id: uptimeCheck
            Kirigami.FormData.label: i18n("System:")
            text: i18n("UPTIME – uptime")
        }
        QQC2.CheckBox {
            id: sessionCheck
            text: i18n("SESSION / KERNEL – Plasma version, window system, kernel")
        }
        QQC2.CheckBox {
            id: hostCheck
            text: i18n("HOST – footer with host name")
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18n("Rows this computer has no sensor for (e.g. no battery, no GPU values) are hidden automatically.")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Appearance")
        }

        QQC2.CheckBox {
            id: compactCheck
            Kirigami.FormData.label: i18n("Density:")
            text: i18n("Compact (tighter rows, no detail lines)")
        }
        QQC2.CheckBox {
            id: motionCheck
            Kirigami.FormData.label: i18n("Motion:")
            text: i18n("Reduce animations (LED does not pulse)")
        }
    }
}
