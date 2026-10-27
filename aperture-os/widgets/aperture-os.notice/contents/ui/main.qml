import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

// APERTURE NOTICE: the most recent notifications (1-3) as facility messages.
//
// Data source, in order of preference:
//  1. Inside plasmashell the notification server lives in the same process
//     (NotificationManager.Server.valid). The `Notifications` proxy model then
//     shares Plasma's notification store, including the session history
//     (expired / dismissed notifications).
//  2. Anywhere else (e.g. `plasmawindowed`) a `WatchedNotificationsModel` is
//     created. It registers as a watcher with the running notification server
//     over D-Bus and only sees notifications that arrive after start-up.
// Both models expose the same roles; the widget reads a handful of them into a
// plain JS list, so it does not depend on any delegate API of the models.
PlasmoidItem {
    id: root

    Tokens { id: tokens }

    // ---- configuration --------------------------------------------------
    readonly property int maxItems: Math.max(1, Math.min(3, Plasmoid.configuration.maxItems))
    readonly property bool showLowUrgency: Plasmoid.configuration.showLowUrgency
    readonly property bool heuristics: Plasmoid.configuration.keywordHeuristics
    readonly property bool reduceMotion: Plasmoid.configuration.reduceMotion || tokens.reduceMotionDefault

    // ---- models -----------------------------------------------------------
    readonly property bool serverMode: NotificationManager.Server.valid

    NotificationManager.Notifications {
        id: historyModel
        showNotifications: true
        showJobs: false
        showExpired: true
        showDismissed: true
        showAddedDuringInhibition: true
        urgencies: root.showLowUrgency
                   ? (NotificationManager.Notifications.LowUrgency | NotificationManager.Notifications.NormalUrgency | NotificationManager.Notifications.CriticalUrgency)
                   : (NotificationManager.Notifications.NormalUrgency | NotificationManager.Notifications.CriticalUrgency)
        sortMode: NotificationManager.Notifications.SortByDate
        sortOrder: Qt.DescendingOrder
        groupMode: NotificationManager.Notifications.GroupDisabled
        limit: root.maxItems

        onCountChanged: root.scheduleRefresh()
        onDataChanged: root.scheduleRefresh()
        onModelReset: root.scheduleRefresh()
        onRowsMoved: root.scheduleRefresh()
    }

    Component {
        id: watchedComponent
        NotificationManager.WatchedNotificationsModel {
            onRowsInserted: root.scheduleRefresh()
            onRowsRemoved: root.scheduleRefresh()
            onDataChanged: root.scheduleRefresh()
            onModelReset: root.scheduleRefresh()
        }
    }
    property var watchedModel: null

    onServerModeChanged: setupModels()
    Component.onCompleted: setupModels()

    function setupModels() {
        if (!serverMode && !watchedModel)
            watchedModel = watchedComponent.createObject(root)
        else if (serverMode && watchedModel) {
            watchedModel.destroy()
            watchedModel = null
        }
        scheduleRefresh()
    }

    // ---- flattened view data ------------------------------------------------
    property var items: []
    property int totalCount: 0
    property date now: new Date()

    // Coalesce bursts of model signals into one rebuild.
    Timer {
        id: refreshTimer
        interval: 50
        onTriggered: root.refresh()
    }
    function scheduleRefresh() { refreshTimer.restart() }

    function stripMarkup(text) {
        return String(text || "")
            .replace(/<br\s*\/?>/gi, " ")
            .replace(/<[^>]*>/g, "")
            .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"")
            .replace(/&#39;|&apos;/g, "'").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&")
            .replace(/\s+/g, " ")
            .trim()
    }

    function classify(urgency, summary, body) {
        if (urgency === NotificationManager.Notifications.CriticalUrgency)
            return "CRITICAL"
        if (heuristics) {
            const t = (summary + " " + body).toLowerCase()
            if (/(error|fehler|failed|failure|fehlgeschlagen|nicht möglich|denied|verweigert|crash|abgestürzt)/.test(t))
                return "ERROR"
            if (/(warn|achtung|caution|low battery|akku.*(schwach|niedrig)|almost full|fast voll|expire)/.test(t))
                return "WARN"
            if (/(success|erfolgreich|completed|abgeschlossen|finished|fertig|connected|verbunden|installed|installiert|done)/.test(t))
                return "OK"
        }
        if (urgency === NotificationManager.Notifications.LowUrgency)
            return "LOW"
        return "INFO"
    }

    function kindColor(kind) {
        switch (kind) {
        case "CRITICAL":
        case "ERROR": return tokens.error
        case "WARN": return tokens.warning
        case "OK": return tokens.success
        case "LOW": return tokens.textMuted
        default: return tokens.blue
        }
    }

    function readRow(model, row) {
        const idx = model.index(row, 0)
        const N = NotificationManager.Notifications
        if (model.data(idx, N.TypeRole) === N.JobType)
            return null
        const urgency = Number(model.data(idx, N.UrgencyRole))
        if (!showLowUrgency && urgency === N.LowUrgency)
            return null
        const summary = stripMarkup(model.data(idx, N.SummaryRole))
        const body = stripMarkup(model.data(idx, N.BodyRole))
        const updated = model.data(idx, N.UpdatedRole)
        const created = model.data(idx, N.CreatedRole)
        const when = (updated instanceof Date && !isNaN(updated)) ? updated : created
        const kind = classify(urgency, summary, body)
        return {
            app: stripMarkup(model.data(idx, N.ApplicationNameRole)) || "SYSTEM",
            summary: summary || body,
            body: summary ? body : "",
            time: (when instanceof Date && !isNaN(when)) ? when : null,
            kind: kind,
            critical: kind === "CRITICAL",
            unread: model.data(idx, N.ExpiredRole) !== true && model.data(idx, N.DismissedRole) !== true
        }
    }

    function refresh() {
        const list = []
        if (serverMode) {
            for (let i = 0; i < historyModel.count && list.length < maxItems; ++i) {
                const item = readRow(historyModel, i)
                if (item)
                    list.push(item)
            }
            totalCount = historyModel.activeNotificationsCount + historyModel.expiredNotificationsCount
        } else if (watchedModel) {
            // Watched model appends in arrival order: newest is the last row.
            const rows = watchedModel.rowCount()
            let total = 0
            for (let r = rows - 1; r >= 0; --r) {
                const item = readRow(watchedModel, r)
                if (!item)
                    continue
                ++total
                if (list.length < maxItems)
                    list.push(item)
            }
            totalCount = total
        }
        items = list
        now = new Date()
    }

    onMaxItemsChanged: scheduleRefresh()
    onShowLowUrgencyChanged: scheduleRefresh()
    onHeuristicsChanged: scheduleRefresh()

    // Relative times ("12 MIN") only need minute resolution.
    Timer {
        interval: 30000
        repeat: true
        running: root.items.length > 0
        onTriggered: root.now = new Date()
    }

    function relativeTime(t) {
        if (!t)
            return ""
        const s = Math.max(0, Math.round((now.getTime() - t.getTime()) / 1000))
        if (s < 60)
            return "NOW"
        if (s < 3600)
            return Math.floor(s / 60) + " MIN"
        if (s < 86400)
            return Math.floor(s / 3600) + " H"
        return Math.floor(s / 86400) + " D"
    }
    function clock(t) {
        return t ? Qt.formatTime(t, "HH:mm") : "--:--"
    }

    readonly property var latest: items.length > 0 ? items[0] : null
    readonly property color statusColor: latest ? kindColor(latest.kind) : tokens.textDisabled

    // ---- plasmoid ---------------------------------------------------------
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                    || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    Plasmoid.status: latest && latest.critical ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus
    toolTipMainText: "APERTURE NOTICE"
    toolTipSubText: latest ? latest.kind + " · " + latest.app + ": " + latest.summary : "NO ACTIVE NOTICES"

    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Row {
            id: compactRow
            anchors.centerIn: parent
            spacing: 6
            Led {
                anchors.verticalCenter: parent.verticalCenter
                tk: tokens
                color: root.statusColor
                breathing: root.latest !== null && root.latest.critical
                reduceMotion: root.reduceMotion
            }
            MonoLabel {
                anchors.verticalCenter: parent.verticalCenter
                tk: tokens
                strong: compact.containsMouse || root.expanded
                text: root.latest ? root.latest.kind + " " + root.totalCount : "NOTICE 0"
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: compactRow.implicitWidth
            height: tokens.accentWidth
            color: tokens.orange
            visible: root.expanded
        }
    }

    fullRepresentation: Item {
        // Stable size: room for `maxItems` notices so the desktop widget does
        // not need to grow when messages arrive. Overflow is clipped.
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5
        Layout.preferredHeight: Math.max(content.implicitHeight + Kirigami.Units.smallSpacing * 2,
                                         Kirigami.Units.gridUnit * (2.2 + 4.6 * root.maxItems))
        clip: true

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
                glyph: "◉"
                title: "APERTURE NOTICE"
                subtitle: root.totalCount > 0 ? "LOG // " + (root.totalCount < 10 ? "0" : "") + root.totalCount : "LOG // 00"
            }

            // ---- empty state
            RowLayout {
                visible: root.items.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.largeSpacing

                Rectangle {
                    Layout.preferredWidth: tokens.accentWidth
                    Layout.fillHeight: true
                    color: tokens.alpha(tokens.border, 0.9)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    StatusTag {
                        tk: tokens
                        color: tokens.textMuted
                        text: "NO ACTIVE NOTICES"
                    }
                    MonoLabel {
                        tk: tokens
                        Layout.leftMargin: 17
                        color: tokens.textDisabled
                        text: "ALL SYSTEMS NOMINAL"
                    }
                }
            }

            // ---- notices
            Repeater {
                model: root.items
                delegate: RowLayout {
                    id: notice
                    required property var modelData
                    required property int index
                    readonly property color kindColor: root.kindColor(modelData.kind)

                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    opacity: index === 0 ? 1 : 0.78

                    // urgency signal bar
                    Rectangle {
                        Layout.preferredWidth: tokens.accentWidth
                        Layout.fillHeight: true
                        color: notice.kindColor
                        opacity: notice.index === 0 ? 1 : 0.7
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing + 2
                            StatusTag {
                                tk: tokens
                                color: notice.kindColor
                                text: notice.modelData.kind
                                breathing: notice.index === 0 && notice.modelData.critical
                                reduceMotion: root.reduceMotion
                            }
                            MonoLabel {
                                tk: tokens
                                Layout.fillWidth: true
                                text: "// " + notice.modelData.app
                            }
                            MonoLabel {
                                tk: tokens
                                color: tokens.textDisabled
                                text: root.clock(notice.modelData.time) + "  " + root.relativeTime(notice.modelData.time)
                            }
                        }
                        ValueText {
                            tk: tokens
                            Layout.fillWidth: true
                            text: notice.modelData.summary
                            font.weight: Font.DemiBold
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                        ValueText {
                            tk: tokens
                            visible: text.length > 0
                            Layout.fillWidth: true
                            muted: true
                            text: notice.modelData.body
                            wrapMode: Text.Wrap
                            maximumLineCount: notice.index === 0 ? 3 : 1
                        }
                    }
                }
            }
        }
    }
}
