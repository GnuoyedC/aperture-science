import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

// SYSTEM monitor: CPU, RAM, root disk and network with a 60 sample history.
// Values come from KSystemStats (same daemon as Plasma's system monitor),
// sampled every `updateInterval` seconds (min. 2 s).
PlasmoidItem {
    id: root

    Tokens { id: tokens }
    Fmt { id: fmt; tk: tokens }

    // ---- configuration --------------------------------------------------
    readonly property int interval: Math.max(2, Plasmoid.configuration.updateInterval) * 1000
    readonly property bool showNetwork: Plasmoid.configuration.showNetwork
    readonly property bool showCpu: Plasmoid.configuration.showCpu
    readonly property bool showRam: Plasmoid.configuration.showRam
    readonly property bool showDisk: Plasmoid.configuration.showDisk
    readonly property bool panelNetwork: Plasmoid.configuration.panelNetwork
    readonly property bool needNetwork: showNetwork || panelNetwork
    readonly property bool reduceMotion: Plasmoid.configuration.reduceMotion || tokens.reduceMotionDefault
    readonly property int historySize: 60

    // ---- root file system --------------------------------------------------
    RootDisk { id: rootDisk; active: customDisk.length === 0 }
    readonly property string customDisk: String(Plasmoid.configuration.diskSensor || "").trim()
    readonly property string diskSensorId: customDisk.length > 0 ? customDisk : rootDisk.base + "/usedPercent"
    readonly property bool diskIsRoot: customDisk.length === 0 && rootDisk.isRoot

    // ---- sensors -------------------------------------------------------------
    Sensors.Sensor { id: cpuSensor; sensorId: "cpu/all/usage"; updateRateLimit: root.interval }
    Sensors.Sensor { id: ramSensor; sensorId: "memory/physical/usedPercent"; updateRateLimit: root.interval }
    Sensors.Sensor {
        id: diskSensor
        sensorId: root.diskSensorId
        updateRateLimit: Math.max(root.interval, 10000)
        onStatusChanged: {
            if (status === Sensors.Sensor.Error && root.customDisk.length === 0)
                rootDisk.markFailed()
        }
    }
    Sensors.Sensor {
        id: downSensor
        sensorId: "network/all/download"
        updateRateLimit: root.interval
        enabled: root.needNetwork
    }
    Sensors.Sensor {
        id: upSensor
        sensorId: "network/all/upload"
        updateRateLimit: root.interval
        enabled: root.needNetwork
    }

    readonly property real cpu: Number(cpuSensor.value) || 0
    readonly property real ram: Number(ramSensor.value) || 0
    readonly property real disk: Number(diskSensor.value) || 0
    readonly property real down: Number(downSensor.value) || 0
    readonly property real up: Number(upSensor.value) || 0

    // ---- network history ---------------------------------------------------
    property var downHistory: []
    property var upHistory: []
    readonly property real historyPeak: {
        let m = 0
        for (let i = 0; i < downHistory.length; ++i)
            m = Math.max(m, downHistory[i], upHistory[i] || 0)
        return m
    }

    Timer {
        interval: root.interval
        repeat: true
        running: root.showNetwork
        triggeredOnStart: true
        onTriggered: {
            const d = root.downHistory.slice(-(root.historySize - 1))
            const u = root.upHistory.slice(-(root.historySize - 1))
            d.push(root.down)
            u.push(root.up)
            root.downHistory = d
            root.upHistory = u
        }
    }

    readonly property string worstState: {
        const m = Math.max(cpu, ram, disk)
        return fmt.levelState(m)
    }

    // ---- plasmoid ---------------------------------------------------------
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                    || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    toolTipMainText: "SYSTEM"
    toolTipSubText: "CPU " + Math.round(cpu) + " %  ·  RAM " + Math.round(ram) + " %  ·  DISK " + Math.round(disk) + " %"
                    + (needNetwork ? "\n↓ " + fmt.rate(down) + "  ↑ " + fmt.rate(up) : "")

    // ---- task bar ---------------------------------------------------------
    function pct(v) {
        const n = Math.round(v)
        return (n < 10 ? "  " : n < 100 ? " " : "") + n + "%"
    }
    readonly property var panelItems: {
        const c = Plasmoid.configuration
        const l = []
        if (c.panelCpu)
            l.push("CPU " + pct(cpu))
        if (c.panelRam)
            l.push("RAM " + pct(ram))
        if (c.panelDisk)
            l.push("DISK " + pct(disk))
        if (c.panelNetwork)
            l.push("↓ " + fmt.rate(down) + "  ↑ " + fmt.rate(up))
        return l
    }

    compactRepresentation: PanelStats {
        tk: tokens
        items: root.panelItems
        showLed: Plasmoid.configuration.panelLed
        ledColor: root.worstState === "OK" ? tokens.success : fmt.levelColor(Math.max(root.cpu, root.ram, root.disk))
        clickable: Plasmoid.configuration.clickToExpand
        expanded: root.expanded
        vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        onActivated: root.expanded = !root.expanded
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 13
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: content.implicitHeight + Kirigami.Units.smallSpacing * 2
        Layout.preferredHeight: Layout.minimumHeight

        ColumnLayout {
            id: content
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            PanelHeader {
                tk: tokens
                Layout.fillWidth: true
                title: "SYSTEM"
                subtitle: "SYS.MON // " + Math.round(root.interval / 1000) + " S"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing + 4

                Repeater {
                    model: [
                        { label: "CPU", value: root.cpu, on: root.showCpu },
                        { label: "RAM", value: root.ram, on: root.showRam },
                        { label: root.diskIsRoot ? "DISK /" : "DISK", value: root.disk, on: root.showDisk }
                    ].filter(r => r.on)
                    delegate: MeterRow {
                        required property var modelData
                        tk: tokens
                        formatter: fmt
                        Layout.fillWidth: true
                        label: modelData.label
                        value: modelData.value
                        labelWidth: Kirigami.Units.gridUnit * 3.2
                        valueWidth: Kirigami.Units.gridUnit * 2.4
                        stateWidth: Kirigami.Units.gridUnit * 1.8
                        columnSpacing: Kirigami.Units.largeSpacing + 2
                    }
                }
            }

            // ---- network
            ColumnLayout {
                visible: root.showNetwork
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing + 2

                Divider { tk: tokens; Layout.fillWidth: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing + 2
                    MonoLabel {
                        tk: tokens
                        text: "NET"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3.2
                    }
                    Row {
                        spacing: 5
                        MonoLabel { tk: tokens; text: "↓"; color: tokens.blue; anchors.baseline: downText.baseline }
                        ValueText { id: downText; tk: tokens; text: fmt.rate(root.down) }
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 5
                        MonoLabel { tk: tokens; text: "↑"; color: tokens.textMuted; anchors.baseline: upText.baseline }
                        ValueText { id: upText; tk: tokens; text: fmt.rate(root.up) }
                    }
                }

                Sparkline {
                    tk: tokens
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    primary: root.downHistory
                    secondary: root.upHistory
                    capacity: root.historySize
                    peak: root.historyPeak
                }

                RowLayout {
                    Layout.fillWidth: true
                    MonoLabel {
                        tk: tokens
                        color: tokens.textDisabled
                        text: "-" + Math.round(root.historySize * root.interval / 1000) + " S"
                    }
                    Item { Layout.fillWidth: true }
                    MonoLabel {
                        tk: tokens
                        color: tokens.textDisabled
                        font.capitalization: Font.MixedCase
                        text: "PEAK " + fmt.rate(root.historyPeak)
                    }
                }
            }
        }
    }
}
