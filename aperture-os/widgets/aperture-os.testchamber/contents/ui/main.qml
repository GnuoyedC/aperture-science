import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

// TEST CHAMBER status panel.
// Every row can be switched on/off in the settings; rows whose sensor does
// not exist on this machine hide themselves. Data: KSystemStats sensors
// (only the ones of visible rows are enabled, rate limited to >= 2 s) and the
// powermanagement engine for the battery. No polling of its own.
PlasmoidItem {
    id: root

    Tokens { id: tokens }
    Fmt { id: fmt; tk: tokens }

    // ---- configuration --------------------------------------------------
    readonly property var cfg: Plasmoid.configuration
    readonly property int chamberNumber: cfg.chamberNumber
    readonly property int tempWarning: cfg.tempWarning
    readonly property bool reduceMotion: cfg.reduceMotion || tokens.reduceMotionDefault
    readonly property bool dense: cfg.compactLayout

    readonly property bool showCore: cfg.showCore
    readonly property bool showPortal: cfg.showPortal
    readonly property bool showPower: cfg.showPower
    readonly property bool showCpuTemp: cfg.showCpuTemp
    readonly property bool showCpuLoad: cfg.showCpuLoad
    readonly property bool showLoadAverage: cfg.showLoadAverage
    readonly property bool showGpu: cfg.showGpu
    readonly property bool showFan: cfg.showFan
    readonly property bool showMemory: cfg.showMemory
    readonly property bool showSwap: cfg.showSwap
    readonly property bool showDisk: cfg.showDisk
    readonly property bool showNetwork: cfg.showNetwork
    readonly property bool showUptime: cfg.showUptime
    readonly property bool showSession: cfg.showSession
    readonly property bool showHost: cfg.showHost

    // A sensor is subscribed when its popup row OR its task bar entry needs it.
    readonly property bool needPower: showPower || cfg.panelPower
    readonly property bool needCpuLoad: showCpuLoad || cfg.panelCpuLoad
    readonly property bool needGpu: showGpu || cfg.panelGpu
    readonly property bool needFan: showFan || cfg.panelFan
    readonly property bool needMemory: showMemory || cfg.panelMemory
    readonly property bool needSwap: showSwap || cfg.panelSwap
    readonly property bool needDisk: showDisk || cfg.panelDisk
    readonly property bool needNetwork: showNetwork || cfg.panelNetwork
    readonly property bool needUptime: showUptime || cfg.panelUptime

    readonly property string chamberLabel: "TEST CHAMBER " + (chamberNumber < 10 ? "0" : "") + chamberNumber

    function ready(sensor) {
        return sensor.status === Sensors.Sensor.Ready
    }

    // ---- power ----------------------------------------------------------
    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: root.needPower ? ["Battery", "AC Adapter"] : []
    }
    readonly property var batteryData: pmSource.data["Battery"] || ({})
    readonly property bool hasBattery: batteryData["Has Battery"] === true
    readonly property bool acPlugged: (pmSource.data["AC Adapter"] || ({}))["Plugged in"] === true
    readonly property int batteryPercent: hasBattery ? Number(batteryData["Percent"] || 0) : 100
    readonly property string batteryState: hasBattery ? String(batteryData["State"] || "") : "NoBattery"

    readonly property string powerState: {
        if (!hasBattery)
            return "MAINS"
        if (batteryPercent < 10 && !acPlugged)
            return "CRITICAL"
        if (batteryPercent < 25 && !acPlugged)
            return "LOW"
        switch (batteryState) {
        case "Charging": return "CHARGING"
        case "Discharging": return "DISCHARGING"
        case "FullyCharged": return "FULL"
        default: return acPlugged ? "CHARGE HOLD" : "BATTERY"
        }
    }
    readonly property color powerColor: powerState === "CRITICAL" ? tokens.error
                                      : powerState === "LOW" ? tokens.warning
                                      : tokens.blue

    // ---- CPU ----------------------------------------------------------------
    Sensors.Sensor {
        id: tempSensor
        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: 4000      // always on: also drives the panel LED
    }
    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: 2000
        enabled: root.needCpuLoad
    }
    Sensors.Sensor { id: load1Sensor; sensorId: "cpu/loadaverages/loadaverage1"; updateRateLimit: 5000; enabled: root.showLoadAverage }
    Sensors.Sensor { id: load5Sensor; sensorId: "cpu/loadaverages/loadaverage5"; updateRateLimit: 5000; enabled: root.showLoadAverage }
    Sensors.Sensor { id: load15Sensor; sensorId: "cpu/loadaverages/loadaverage15"; updateRateLimit: 5000; enabled: root.showLoadAverage }
    Sensors.Sensor { id: cpuCountSensor; sensorId: "cpu/all/cpuCount"; updateRateLimit: 60000; enabled: root.showLoadAverage }

    readonly property real temperature: Number(tempSensor.value) || 0
    readonly property bool hasTemperature: temperature > 0
    readonly property string tempState: !hasTemperature ? "NO DATA"
                                      : temperature >= tempWarning + 10 ? "CRITICAL"
                                      : temperature >= tempWarning ? "WARN"
                                      : "NOMINAL"
    readonly property color tempColor: tempState === "CRITICAL" ? tokens.error
                                     : tempState === "WARN" ? tokens.warning
                                     : tempState === "NOMINAL" ? tokens.success
                                     : tokens.textDisabled

    // CORE follows the thermal state: the chamber is only "online" while the
    // processor is within its envelope.
    readonly property string coreState: tempState === "CRITICAL" ? "OVERHEAT"
                                      : tempState === "WARN" ? "STRAINED"
                                      : "ONLINE"
    readonly property color coreColor: tempState === "CRITICAL" ? tokens.error
                                     : tempState === "WARN" ? tokens.warning
                                     : tokens.success

    readonly property real cpu: Number(cpuSensor.value) || 0
    readonly property real load1: Number(load1Sensor.value) || 0
    readonly property int cpuCount: Math.max(1, Number(cpuCountSensor.value) || 1)
    readonly property string loadState: load1 >= cpuCount * 2 ? "CRIT" : load1 >= cpuCount ? "HIGH" : "OK"
    readonly property color loadColor: loadState === "CRIT" ? tokens.error
                                     : loadState === "HIGH" ? tokens.warning
                                     : tokens.textDisabled

    // ---- memory / disk ------------------------------------------------------
    Sensors.Sensor { id: memSensor; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000; enabled: root.needMemory }
    Sensors.Sensor { id: memUsedSensor; sensorId: "memory/physical/used"; updateRateLimit: 4000; enabled: root.showMemory && !root.dense }
    Sensors.Sensor { id: memTotalSensor; sensorId: "memory/physical/total"; updateRateLimit: 60000; enabled: root.showMemory && !root.dense }
    Sensors.Sensor { id: swapSensor; sensorId: "memory/swap/usedPercent"; updateRateLimit: 4000; enabled: root.needSwap }
    Sensors.Sensor { id: swapUsedSensor; sensorId: "memory/swap/used"; updateRateLimit: 4000; enabled: root.showSwap }
    Sensors.Sensor { id: swapTotalSensor; sensorId: "memory/swap/total"; updateRateLimit: 60000; enabled: root.showSwap }

    RootDisk { id: rootDisk; active: root.needDisk }
    Sensors.Sensor {
        id: diskSensor
        sensorId: rootDisk.base + "/usedPercent"
        updateRateLimit: 10000
        enabled: root.needDisk
        onStatusChanged: if (status === Sensors.Sensor.Error) rootDisk.markFailed()
    }
    Sensors.Sensor { id: diskUsedSensor; sensorId: rootDisk.base + "/used"; updateRateLimit: 10000; enabled: root.showDisk && !root.dense }
    Sensors.Sensor { id: diskTotalSensor; sensorId: rootDisk.base + "/total"; updateRateLimit: 60000; enabled: root.showDisk && !root.dense }

    readonly property real swapTotal: Number(swapTotalSensor.value) || 0

    // ---- network ------------------------------------------------------------
    Sensors.Sensor { id: downSensor; sensorId: "network/all/download"; updateRateLimit: 2000; enabled: root.needNetwork }
    Sensors.Sensor { id: upSensor; sensorId: "network/all/upload"; updateRateLimit: 2000; enabled: root.needNetwork }

    // ---- GPU / fan: sensor IDs depend on the hardware -----------------------
    // Asks KSystemStats once (kstatsviewer --list) which gpu/gpuN devices and
    // lmsensors fan inputs exist. Only runs when one of the two rows is on.
    property string gpuBase: ""
    property string fanId: ""
    property bool discovered: false
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            const ids = String(data["stdout"] || "").split("\n")
            let gpu = "", fan = "", fallbackFan = ""
            for (let i = 0; i < ids.length; ++i) {
                const id = ids[i].trim()
                if (gpu.length === 0 && /^gpu\/gpu[0-9]+$/.test(id))
                    gpu = id
                else if (/^lmsensors\/[^\/]+\/fan[0-9]+$/.test(id)) {
                    // acpi_fan only knows on/off and usually reports 0 RPM
                    if (id.indexOf("acpi_fan") >= 0) {
                        if (fallbackFan.length === 0)
                            fallbackFan = id
                    } else if (fan.length === 0) {
                        fan = id
                    }
                }
            }
            root.gpuBase = gpu
            root.fanId = fan.length > 0 ? fan : fallbackFan
            exec.disconnectSource(source)
        }
    }
    function discover() {
        if (!discovered && (needGpu || needFan)) {
            discovered = true
            exec.connectSource("kstatsviewer --list 2>/dev/null | cut -d' ' -f1 | grep -E '^(gpu/gpu[0-9]+|lmsensors/[^/]+/fan[0-9]+)$' | sort -u")
        }
    }
    onNeedGpuChanged: discover()
    onNeedFanChanged: discover()

    Sensors.Sensor { id: gpuUsageSensor; sensorId: root.gpuBase.length > 0 ? root.gpuBase + "/usage" : ""; updateRateLimit: 4000; enabled: root.needGpu }
    Sensors.Sensor { id: gpuTempSensor; sensorId: root.gpuBase.length > 0 ? root.gpuBase + "/temperature" : ""; updateRateLimit: 4000; enabled: root.needGpu }
    Sensors.Sensor { id: fanSensor; sensorId: root.fanId; updateRateLimit: 4000; enabled: root.needFan }

    readonly property real gpuUsage: Number(gpuUsageSensor.value) || 0
    readonly property real gpuTemp: Number(gpuTempSensor.value) || 0
    // Some drivers (e.g. Intel iGPUs) expose gpu/gpuN but always report 0:
    // only show the row once real data has arrived.
    property bool gpuHasData: false
    onGpuUsageChanged: if (gpuUsage > 0) gpuHasData = true
    onGpuTempChanged: if (gpuTemp > 0) gpuHasData = true
    readonly property real fanRpm: Number(fanSensor.value) || 0

    // ---- system -------------------------------------------------------------
    Sensors.Sensor { id: uptimeSensor; sensorId: "os/system/uptime"; updateRateLimit: 30000; enabled: root.needUptime }
    Sensors.Sensor { id: hostSensor; sensorId: "os/system/hostname"; updateRateLimit: 60000; enabled: root.showHost }
    Sensors.Sensor { id: kernelSensor; sensorId: "os/kernel/prettyName"; updateRateLimit: 60000; enabled: root.showSession }
    Sensors.Sensor { id: plasmaSensor; sensorId: "os/plasma/plasmaVersion"; updateRateLimit: 60000; enabled: root.showSession }
    Sensors.Sensor { id: windowSystemSensor; sensorId: "os/plasma/windowsystem"; updateRateLimit: 60000; enabled: root.showSession }

    Component.onCompleted: discover()

    // ---- row visibility (option on AND sensor present) ----------------------
    readonly property bool rowPower: showPower && hasBattery
    readonly property bool rowCpuTemp: showCpuTemp && ready(tempSensor)
    readonly property bool rowCpuLoad: showCpuLoad && ready(cpuSensor)
    readonly property bool rowLoadAverage: showLoadAverage && ready(load1Sensor)
    readonly property bool rowGpu: showGpu && gpuBase.length > 0 && gpuHasData
    readonly property bool rowFan: showFan && fanId.length > 0 && ready(fanSensor)
    readonly property bool rowMemory: showMemory && ready(memSensor)
    readonly property bool rowSwap: showSwap && ready(swapSensor) && swapTotal > 0
    readonly property bool rowDisk: showDisk && ready(diskSensor)
    readonly property bool rowNetwork: showNetwork && ready(downSensor)
    readonly property bool rowUptime: showUptime && ready(uptimeSensor)
    readonly property bool rowSession: showSession && ready(kernelSensor)

    readonly property bool statusBlock: showCore || showPortal || rowPower
    readonly property bool telemetryBlock: rowCpuTemp || rowCpuLoad || rowLoadAverage || rowGpu || rowFan
                                           || rowMemory || rowSwap || rowDisk || rowNetwork
                                           || rowUptime || rowSession

    // ---- plasmoid ---------------------------------------------------------
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    // Compact (LED + label) in panels, full panel everywhere else.
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                    || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    toolTipMainText: chamberLabel
    toolTipSubText: {
        const parts = ["CORE " + coreState]
        if (hasTemperature)
            parts.push(Math.round(temperature) + " °C")
        if (rowCpuLoad)
            parts.push("CPU " + Math.round(cpu) + " %")
        if (rowMemory)
            parts.push("MEM " + Math.round(Number(memSensor.value) || 0) + " %")
        if (rowPower)
            parts.push("POWER " + batteryPercent + " % " + powerState)
        return parts.join("  ·  ")
    }

    // ---- task bar ---------------------------------------------------------
    function pct(v) {
        const n = Math.round(v)
        return (n < 10 ? "  " : n < 100 ? " " : "") + n + "%"
    }
    readonly property var panelItems: {
        const l = []
        if (cfg.panelLabel)
            l.push("CH" + (chamberNumber < 10 ? "0" : "") + chamberNumber)
        if (cfg.panelCpuTemp && hasTemperature)
            l.push("TEMP " + Math.round(temperature) + " °C")
        if (cfg.panelCpuLoad && ready(cpuSensor))
            l.push("CPU " + pct(cpu))
        if (cfg.panelMemory && ready(memSensor))
            l.push("MEM " + pct(Number(memSensor.value) || 0))
        if (cfg.panelSwap && ready(swapSensor))
            l.push("SWAP " + pct(Number(swapSensor.value) || 0))
        if (cfg.panelDisk && ready(diskSensor))
            l.push("DISK " + pct(Number(diskSensor.value) || 0))
        if (cfg.panelGpu && gpuHasData)
            l.push("GPU " + pct(gpuUsage))
        if (cfg.panelFan && fanId.length > 0 && ready(fanSensor))
            l.push("FAN " + Math.round(fanRpm))
        if (cfg.panelPower && hasBattery)
            l.push("BAT " + pct(batteryPercent))
        if (cfg.panelNetwork && ready(downSensor))
            l.push("↓ " + fmt.rate(downSensor.value) + "  ↑ " + fmt.rate(upSensor.value))
        if (cfg.panelUptime && ready(uptimeSensor))
            l.push("UP " + fmt.duration(uptimeSensor.value))
        return l
    }

    compactRepresentation: PanelStats {
        tk: tokens
        items: root.panelItems
        showLed: cfg.panelLed
        ledColor: root.coreColor
        breathing: true
        reduceMotion: root.reduceMotion
        clickable: cfg.clickToExpand
        expanded: root.expanded
        vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        onActivated: root.expanded = !root.expanded
    }

    fullRepresentation: Item {
        id: full

        // shared column geometry so all rows line up like a grid
        readonly property real labelWidth: Kirigami.Units.gridUnit * 4.2
        readonly property real valueWidth: Kirigami.Units.gridUnit * 2.6
        readonly property real stateWidth: Kirigami.Units.gridUnit * 2
        readonly property real colSpacing: Kirigami.Units.largeSpacing + 2

        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredWidth: Kirigami.Units.gridUnit * 17
        Layout.minimumHeight: content.implicitHeight + Kirigami.Units.smallSpacing * 2
        Layout.preferredHeight: Layout.minimumHeight

        ColumnLayout {
            id: content
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: root.dense ? Kirigami.Units.smallSpacing + 2 : Kirigami.Units.largeSpacing

            PanelHeader {
                tk: tokens
                Layout.fillWidth: true
                title: root.chamberLabel
                subtitle: "ENRICHMENT CTR"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.dense ? 3 : Kirigami.Units.smallSpacing + 3

                // ---- status block
                InfoRow {
                    visible: root.showCore
                    tk: tokens; label: "CORE"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    StatusTag {
                        tk: tokens
                        color: root.coreColor
                        text: root.coreState
                        breathing: true
                        reduceMotion: root.reduceMotion
                    }
                }
                InfoRow {
                    visible: root.showPortal
                    tk: tokens; label: "PORTAL"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    StatusTag { tk: tokens; color: tokens.blue; text: "STANDBY" }
                }
                MeterRow {
                    visible: root.rowPower
                    tk: tokens; formatter: fmt
                    labelWidth: full.labelWidth; valueWidth: full.valueWidth
                    stateWidth: full.stateWidth; columnSpacing: full.colSpacing
                    Layout.fillWidth: true
                    label: "POWER"
                    segmented: true
                    value: root.batteryPercent
                    barColor: root.powerColor
                    stateText: root.powerState === "CRITICAL" ? "CRIT" : root.powerState === "LOW" ? "LOW" : "OK"
                    stateColor: root.powerState === "CRITICAL" || root.powerState === "LOW" ? root.powerColor : tokens.textDisabled
                    showDetail: !root.dense
                    detail: root.powerState + "  //  " + (root.acPlugged ? "AC LINKED" : "AC OFFLINE")
                }

                Divider {
                    tk: tokens
                    visible: root.statusBlock && root.telemetryBlock
                    Layout.fillWidth: true
                    Layout.topMargin: root.dense ? 0 : 2
                    Layout.bottomMargin: root.dense ? 0 : 2
                    opacity: 0.6
                }

                // ---- processor
                InfoRow {
                    visible: root.rowCpuTemp
                    tk: tokens; label: "CPU TEMP"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    ValueText {
                        tk: tokens
                        text: root.hasTemperature ? Math.round(root.temperature) + " °C" : "– °C"
                        muted: !root.hasTemperature
                    }
                    Item { Layout.fillWidth: true }
                    StatusTag { tk: tokens; color: root.tempColor; text: root.tempState }
                }
                MeterRow {
                    visible: root.rowCpuLoad
                    tk: tokens; formatter: fmt
                    labelWidth: full.labelWidth; valueWidth: full.valueWidth
                    stateWidth: full.stateWidth; columnSpacing: full.colSpacing
                    Layout.fillWidth: true
                    label: "CPU LOAD"
                    value: root.cpu
                }
                InfoRow {
                    visible: root.rowLoadAverage
                    tk: tokens; label: "LOAD AVG"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    ValueText {
                        tk: tokens
                        text: [load1Sensor, load5Sensor, load15Sensor]
                              .map(s => (Number(s.value) || 0).toFixed(2)).join("  ")
                        Layout.fillWidth: true
                    }
                    MonoLabel {
                        tk: tokens
                        text: root.loadState
                        color: root.loadColor
                        Layout.minimumWidth: full.stateWidth
                    }
                }
                MeterRow {
                    visible: root.rowGpu
                    tk: tokens; formatter: fmt
                    labelWidth: full.labelWidth; valueWidth: full.valueWidth
                    stateWidth: full.stateWidth; columnSpacing: full.colSpacing
                    Layout.fillWidth: true
                    label: "GPU"
                    value: root.gpuUsage
                    showDetail: !root.dense
                    detail: root.gpuTemp > 0 ? "TEMP " + Math.round(root.gpuTemp) + " °C" : ""
                }
                InfoRow {
                    visible: root.rowFan
                    tk: tokens; label: "FAN"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    ValueText { tk: tokens; text: Math.round(root.fanRpm) + " RPM" }
                    Item { Layout.fillWidth: true }
                    StatusTag {
                        tk: tokens
                        color: root.fanRpm > 0 ? tokens.blue : tokens.textDisabled
                        text: root.fanRpm > 0 ? "ACTIVE" : "IDLE"
                    }
                }

                // ---- memory / storage
                MeterRow {
                    visible: root.rowMemory
                    tk: tokens; formatter: fmt
                    labelWidth: full.labelWidth; valueWidth: full.valueWidth
                    stateWidth: full.stateWidth; columnSpacing: full.colSpacing
                    Layout.fillWidth: true
                    label: "MEMORY"
                    value: Number(memSensor.value) || 0
                    showDetail: !root.dense && Number(memTotalSensor.value) > 0
                    detail: fmt.gib(memUsedSensor.value) + " / " + fmt.gib(memTotalSensor.value) + " GiB"
                }
                MeterRow {
                    visible: root.rowSwap
                    tk: tokens; formatter: fmt
                    labelWidth: full.labelWidth; valueWidth: full.valueWidth
                    stateWidth: full.stateWidth; columnSpacing: full.colSpacing
                    Layout.fillWidth: true
                    label: "SWAP"
                    value: Number(swapSensor.value) || 0
                    showDetail: !root.dense
                    detail: fmt.gib(swapUsedSensor.value) + " / " + fmt.gib(root.swapTotal) + " GiB"
                }
                MeterRow {
                    visible: root.rowDisk
                    tk: tokens; formatter: fmt
                    labelWidth: full.labelWidth; valueWidth: full.valueWidth
                    stateWidth: full.stateWidth; columnSpacing: full.colSpacing
                    Layout.fillWidth: true
                    label: rootDisk.isRoot ? "DISK /" : "DISK"
                    value: Number(diskSensor.value) || 0
                    showDetail: !root.dense && Number(diskTotalSensor.value) > 0
                    detail: fmt.gib(diskUsedSensor.value) + " / " + fmt.gib(diskTotalSensor.value) + " GiB"
                }

                // ---- network
                InfoRow {
                    visible: root.rowNetwork
                    tk: tokens; label: "NETWORK"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    Row {
                        spacing: 5
                        MonoLabel { tk: tokens; text: "↓"; color: tokens.blue; anchors.baseline: downText.baseline }
                        ValueText { id: downText; tk: tokens; text: fmt.rate(downSensor.value) }
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 5
                        MonoLabel { tk: tokens; text: "↑"; color: tokens.textMuted; anchors.baseline: upText.baseline }
                        ValueText { id: upText; tk: tokens; text: fmt.rate(upSensor.value) }
                    }
                }

                // ---- system
                InfoRow {
                    visible: root.rowUptime
                    tk: tokens; label: "UPTIME"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    ValueText { tk: tokens; text: fmt.duration(uptimeSensor.value) }
                }
                InfoRow {
                    visible: root.rowSession
                    tk: tokens; label: "SESSION"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    ValueText {
                        tk: tokens
                        Layout.fillWidth: true
                        text: ["Plasma " + String(plasmaSensor.value || "?"), String(windowSystemSensor.value || "")]
                              .filter(s => s.length > 0).join("  ·  ")
                    }
                }
                InfoRow {
                    visible: root.rowSession
                    tk: tokens; label: "KERNEL"; labelWidth: full.labelWidth; spacing: full.colSpacing
                    Layout.fillWidth: true
                    ValueText {
                        tk: tokens
                        Layout.fillWidth: true
                        text: String(kernelSensor.value || "")
                    }
                }
            }

            ColumnLayout {
                visible: root.showHost
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing + 1
                Divider { tk: tokens; Layout.fillWidth: true }
                RowLayout {
                    Layout.fillWidth: true
                    MonoLabel {
                        tk: tokens
                        Layout.fillWidth: true
                        color: tokens.textDisabled
                        text: "HOST // " + (hostSensor.value ? String(hostSensor.value) : "LOCAL")
                    }
                    MonoLabel {
                        tk: tokens
                        color: tokens.textDisabled
                        text: "APERTURE OS"
                    }
                }
            }
        }
    }
}
