pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.coreaddons as KCoreAddons

// Popup content. Background is the Plasma Style's dialog glass; nothing heavy
// is drawn here. Layout:
//   header (emblem, title, chamber/host) · search · favourites + categories
//   (or category content / search results) · footer (user, status, session)
FocusScope {
    id: root

    readonly property Tokens tk: launcher.tk

    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 26
    Layout.preferredWidth: Kirigami.Units.gridUnit * 25
    Layout.preferredHeight: Kirigami.Units.gridUnit * 34

    readonly property bool showFavorites: Plasmoid.configuration.showFavorites
    readonly property bool showCategories: Plasmoid.configuration.showCategories
    readonly property int maxResults: Plasmoid.configuration.maxResults

    // ---- navigation state ---------------------------------------------------
    // crumbs: [{ model, title }] for the category drill-down
    property var crumbs: []
    readonly property var currentCategory: crumbs.length > 0 ? crumbs[crumbs.length - 1] : null
    readonly property string mode: searchField.text.length > 0 ? "search"
        : (currentCategory ? "category" : "home")

    function reset() {
        launcher.hoverActive = false
        searchField.text = ""
        crumbs = []
        favGrid.currentIndex = 0
        catList.currentIndex = 0
        searchField.forceActiveFocus(Qt.ShortcutFocusReason)
    }

    function openCategory(model, title) {
        if (!model)
            return
        crumbs = crumbs.concat([{ model: model, title: title }])
        appList.currentIndex = 0
        appList.forceActiveFocus(Qt.TabFocusReason)
    }

    function goBack() {
        if (crumbs.length === 0)
            return false
        crumbs = crumbs.slice(0, crumbs.length - 1)
        if (crumbs.length === 0)
            (catList.visible ? catList : searchField).forceActiveFocus(Qt.BacktabFocusReason)
        return true
    }

    function closePopup() {
        launcher.expanded = false
    }

    // model.trigger() returns true when the popup should close
    function launch(model, row) {
        if (!model || row < 0)
            return
        if (model.trigger(row, "", null))
            closePopup()
    }

    function launchResult(index) {
        if (index < 0 || index >= resultsProxy.count)
            return
        const src = resultsProxy.mapToSource(resultsProxy.index(index, 0))
        launch(resultsProxy.sourceModel, src.row)
    }

    function activateAppRow(index) {
        const model = appList.model
        if (!model)
            return
        const idx = model.index(index, 0)
        const hasChildren = model.data(idx, model.KItemModels.KRoleNames.role("hasChildren"))
        if (hasChildren)
            openCategory(model.modelForRow(index), model.data(idx, Qt.DisplayRole))
        else
            launch(model, index)
    }

    // Printable keys typed while a list has focus go into the search field.
    function forwardTyping(event) {
        if (event.text.length === 0 || (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
            return false
        const c = event.text.charCodeAt(0)
        if (c < 32 || c === 127)
            return false
        searchField.forceActiveFocus(Qt.ShortcutFocusReason)
        searchField.insert(searchField.cursorPosition, event.text)
        return true
    }

    // Tab order: search -> content sections -> session buttons -> search
    function sections() {
        const s = [searchField]
        if (mode === "search") {
            if (resultsView.count > 0) s.push(resultsView)
        } else if (mode === "category") {
            s.push(backButton)
            if (appList.count > 0) s.push(appList)
        } else {
            if (favGrid.visible && favGrid.count > 0) s.push(favGrid)
            if (catList.visible && catList.count > 0) s.push(catList)
        }
        const firstPower = powerRow.firstButton()
        if (firstPower) s.push(firstPower)
        return s
    }
    function focusNextSection(from, backwards) {
        const s = sections()
        let i = -1
        for (let k = 0; k < s.length; ++k) {
            if (s[k] === from) { i = k; break }
        }
        if (i < 0) i = 0
        const n = (i + (backwards ? s.length - 1 : 1)) % s.length
        s[n].forceActiveFocus(backwards ? Qt.BacktabFocusReason : Qt.TabFocusReason)
    }

    function contextMenu(item, model, row, x, y, sourceModel, sourceRow) {
        const data = {
            hasActionList: model.data(model.index(row, 0), model.KItemModels.KRoleNames.role("hasActionList")),
            actionList: model.data(model.index(row, 0), model.KItemModels.KRoleNames.role("actionList")),
            favoriteId: model.data(model.index(row, 0), model.KItemModels.KRoleNames.role("favoriteId")),
        }
        let actions = actionMenu.buildActions(data, launcher.rootModel.favoritesModel)
        if (model === launcher.rootModel.favoritesModel && model.count > 1) {
            const fav = model
            const move = (to) => ({ fav: fav, from: row, to: to })
            actions = actions.concat([{ type: "separator" }])
            if (row > 0)
                actions.push({ text: i18n("Move forward"), icon: "go-previous",
                               actionId: "_aperture_fav_move", actionArgument: move(row - 1) })
            if (row < model.count - 1)
                actions.push({ text: i18n("Move back"), icon: "go-next",
                               actionId: "_aperture_fav_move", actionArgument: move(row + 1) })
        }
        if (actions.length === 0)
            return
        const srcModel = sourceModel ?? model
        const srcRow = sourceRow ?? row
        actionMenu.open(item, actions, x, y, (id, arg) => srcModel.trigger(srcRow, id, arg))
    }

    Connections {
        target: launcher
        function onExpandedChanged() {
            if (launcher.expanded)
                root.reset()
        }
    }

    // First run without any favourites: seed the configured defaults into
    // the shared KActivities favourites (the same store Kickoff uses).
    function seedFavorites() {
        const fav = launcher.rootModel.favoritesModel
        if (Plasmoid.configuration.favoritesSeeded || !fav || fav.count > 0)
            return
        const all = launcher.rootModel.count > 0 ? launcher.rootModel.modelForRow(0) : null
        const ids = []
        if (all) {
            const role = all.KItemModels.KRoleNames.role("favoriteId")
            for (let i = 0; i < all.count; ++i)
                ids.push(String(all.data(all.index(i, 0), role) ?? ""))
        }
        const find = w => {
            if (w.indexOf("://") > 0)
                return w
            return ids.find(id => id === w || id === "applications:" + w)
                ?? ids.find(id => id.replace(/^applications:/, "").startsWith(w))
        }
        const picked = []
        for (const entry of Plasmoid.configuration.defaultFavorites) {
            const hit = String(entry).split("|").map(find).find(id => !!id)
            if (hit && picked.indexOf(hit) < 0)
                picked.push(hit)
        }
        for (const id of picked) fav.addFavorite(id)
        Plasmoid.configuration.favoritesSeeded = true
    }

    Component.onCompleted: {
        launcher.rootModel.refresh()
        seedFavorites()
        reset()
    }

    Keys.onEscapePressed: event => {
        if (searchField.text.length > 0)
            searchField.text = ""
        else if (!goBack())
            closePopup()
        event.accepted = true
    }

    // short fade when the content area switches (home / category / search)
    onModeChanged: if (launcher.fadeDuration > 0) contentFade.restart()
    NumberAnimation {
        id: contentFade
        target: contentArea
        property: "opacity"
        from: 0.35
        to: 1
        duration: launcher.fadeDuration
        easing.type: Easing.OutCubic
    }

    ActionMenu {
        id: actionMenu
        onCloseRequested: root.closePopup()
    }

    KCoreAddons.KUser { id: kuser }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing * 2

        // ---- header ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing * 2

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                Layout.alignment: Qt.AlignVCenter
                source: "aperture-os"
                fallback: "start-here-kde"
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: "APERTURE OS"
                    color: root.tk.text
                    font.family: root.tk.displayFamily
                    font.weight: Font.DemiBold
                    font.pointSize: root.tk.largeSize
                    font.letterSpacing: 2
                    textFormat: Text.PlainText
                    Accessible.role: Accessible.Heading
                }
                MonoLabel {
                    Layout.fillWidth: true
                    tk: root.tk
                    text: "Test Chamber 01 · " + (kuser.host || "localhost")
                    color: root.tk.textDisabled
                }
            }
        }
        Divider {
            tk: root.tk
            accent: true
            Layout.fillWidth: true
        }

        // ---- search ------------------------------------------------------------
        PlasmaExtras.SearchField {
            id: searchField
            Layout.fillWidth: true
            focus: true
            placeholderText: i18n("Search applications …")
            Accessible.name: i18n("Search applications")

            onTextChanged: launcher.searchText = text
            Connections {
                target: launcher
                function onSearchTextChanged() {
                    if (searchField.text !== launcher.searchText)
                        searchField.text = launcher.searchText
                }
            }

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Escape:
                    // let the root decide (clear / back / close)
                    event.accepted = false
                    return
                case Qt.Key_Up:
                    if (root.mode === "search") { resultsView.decrementCurrentIndex(); event.accepted = true }
                    return
                case Qt.Key_Down:
                    if (root.mode === "search") {
                        resultsView.incrementCurrentIndex()
                    } else if (root.mode === "category") {
                        appList.forceActiveFocus(Qt.TabFocusReason)
                    } else if (favGrid.visible && favGrid.count > 0) {
                        favGrid.forceActiveFocus(Qt.TabFocusReason)
                    } else if (catList.visible) {
                        catList.forceActiveFocus(Qt.TabFocusReason)
                    }
                    event.accepted = true
                    return
                case Qt.Key_PageUp:
                case Qt.Key_PageDown:
                    if (root.mode === "search") {
                        const step = event.key === Qt.Key_PageDown ? 5 : -5
                        resultsView.currentIndex = Math.max(0, Math.min(resultsView.count - 1, resultsView.currentIndex + step))
                        event.accepted = true
                    }
                    return
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    if (root.mode === "search")
                        root.launchResult(resultsView.currentIndex)
                    else if (root.mode === "category")
                        root.activateAppRow(appList.currentIndex)
                    event.accepted = true
                    return
                case Qt.Key_Backspace:
                    if (searchField.text.length === 0 && root.goBack())
                        event.accepted = true
                    return
                case Qt.Key_Tab:
                case Qt.Key_Backtab:
                    root.focusNextSection(searchField, event.key === Qt.Key_Backtab)
                    event.accepted = true
                    return
                }
            }
        }

        // ---- content -------------------------------------------------------------
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            // -- home: favourites + categories
            ColumnLayout {
                anchors.fill: parent
                visible: root.mode === "home"
                spacing: Kirigami.Units.smallSpacing

                SectionLabel {
                    Layout.fillWidth: true
                    visible: root.showFavorites
                    tk: root.tk
                    glyph: "◉"
                    text: i18n("Favorites")
                    info: favGrid.count > 0 ? String(favGrid.count).padStart(2, "0") : ""
                }

                GridView {
                    id: favGrid
                    Layout.fillWidth: true
                    visible: root.showFavorites && count > 0
                    readonly property int columns: Math.max(3, Math.floor(width / (Kirigami.Units.gridUnit * 4.6)))
                    readonly property int rows: Math.ceil(count / columns)
                    Layout.preferredHeight: Math.min(rows, 3) * cellHeight
                    cellWidth: Math.floor(width / columns)
                    cellHeight: Math.round(Kirigami.Units.gridUnit * 4)
                    interactive: rows > 3
                    clip: true
                    keyNavigationEnabled: true
                    keyNavigationWraps: false
                    highlightMoveDuration: 0
                    currentIndex: 0
                    activeFocusOnTab: false
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.showFavorites ? launcher.rootModel.favoritesModel : null
                    Accessible.role: Accessible.List
                    Accessible.name: i18n("Favorites")

                    delegate: FavoriteTile {
                        tk: root.tk
                        onActivated: index => root.launch(favGrid.model, index)
                        onContextMenuRequested: (item, index, x, y) => root.contextMenu(item, favGrid.model, index, x, y)
                    }

                    Keys.onPressed: event => {
                        const lastRowStart = (rows - 1) * columns
                        switch (event.key) {
                        case Qt.Key_Up:
                            if (currentIndex < columns) searchField.forceActiveFocus(Qt.BacktabFocusReason)
                            else moveCurrentIndexUp()
                            break
                        case Qt.Key_Down:
                            if (currentIndex >= lastRowStart) {
                                if (catList.visible) { catList.currentIndex = 0; catList.forceActiveFocus(Qt.TabFocusReason) }
                            } else if (currentIndex + columns >= count) {
                                currentIndex = count - 1
                            } else moveCurrentIndexDown()
                            break
                        case Qt.Key_Left: moveCurrentIndexLeft(); break
                        case Qt.Key_Right: moveCurrentIndexRight(); break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            root.launch(model, currentIndex); break
                        case Qt.Key_Menu:
                            if (currentItem) root.contextMenu(currentItem, model, currentIndex); break
                        case Qt.Key_Tab:
                        case Qt.Key_Backtab:
                            root.focusNextSection(favGrid, event.key === Qt.Key_Backtab); break
                        default:
                            if (!root.forwardTyping(event)) return
                        }
                        event.accepted = true
                    }
                }

                PC3.Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.smallSpacing * 2
                    visible: root.showFavorites && favGrid.count === 0
                    text: i18n("No favorites yet – right-click an application → “Add to Favorites”.")
                    wrapMode: Text.Wrap
                    color: root.tk.textMuted
                    font.pointSize: root.tk.uiSize - 1
                }

                SectionLabel {
                    Layout.fillWidth: true
                    Layout.topMargin: root.showFavorites ? Kirigami.Units.smallSpacing : 0
                    visible: root.showCategories
                    tk: root.tk
                    glyph: "▸"
                    text: i18n("Categories")
                }

                ListView {
                    id: catList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.showCategories
                    clip: true
                    model: root.showCategories ? launcher.rootModel : null
                    currentIndex: 0
                    keyNavigationEnabled: true
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds
                    reuseItems: true
                    Accessible.role: Accessible.List
                    Accessible.name: i18n("Categories")
                    rightMargin: catListBar.visible ? catListBar.width : 0
                    PC3.ScrollBar.vertical: PC3.ScrollBar { id: catListBar }

                    delegate: ItemRow {
                        tk: root.tk
                        kind: "category"
                        onActivated: index => root.openCategory(launcher.rootModel.modelForRow(index), model.display)
                    }

                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Up:
                            if (currentIndex <= 0)
                                (favGrid.visible && favGrid.count > 0 ? favGrid : searchField).forceActiveFocus(Qt.BacktabFocusReason)
                            else decrementCurrentIndex()
                            break
                        case Qt.Key_Down: incrementCurrentIndex(); break
                        case Qt.Key_Right:
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (currentIndex >= 0)
                                root.openCategory(launcher.rootModel.modelForRow(currentIndex),
                                                  launcher.rootModel.data(launcher.rootModel.index(currentIndex, 0), Qt.DisplayRole))
                            break
                        case Qt.Key_Tab:
                        case Qt.Key_Backtab:
                            root.focusNextSection(catList, event.key === Qt.Key_Backtab); break
                        default:
                            if (!root.forwardTyping(event)) return
                        }
                        event.accepted = true
                    }
                }

                Item {
                    // keeps favourites at the top when categories are hidden
                    visible: !root.showCategories
                    Layout.fillHeight: true
                }
            }

            // -- category drill-down
            ColumnLayout {
                anchors.fill: parent
                visible: root.mode === "category"
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PC3.ToolButton {
                        id: backButton
                        icon.name: "go-previous"
                        text: i18n("Back")
                        display: PC3.AbstractButton.IconOnly
                        PC3.ToolTip.text: i18n("Back (Backspace)")
                        PC3.ToolTip.visible: hovered
                        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                        onClicked: root.goBack()
                        Keys.onTabPressed: root.focusNextSection(backButton, false)
                        Keys.onBacktabPressed: root.focusNextSection(backButton, true)
                        Keys.onDownPressed: appList.forceActiveFocus(Qt.TabFocusReason)
                    }
                    SectionLabel {
                        Layout.fillWidth: true
                        tk: root.tk
                        glyph: "◉"
                        text: root.currentCategory ? root.currentCategory.title : ""
                        info: appList.count > 0 ? String(appList.count).padStart(2, "0") : ""
                    }
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.currentCategory ? root.currentCategory.model : null
                    currentIndex: 0
                    keyNavigationEnabled: true
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds
                    reuseItems: true
                    Accessible.role: Accessible.List
                    Accessible.name: root.currentCategory ? root.currentCategory.title : ""
                    rightMargin: appListBar.visible ? appListBar.width : 0
                    PC3.ScrollBar.vertical: PC3.ScrollBar { id: appListBar }

                    delegate: ItemRow {
                        tk: root.tk
                        kind: "app"
                        onActivated: index => root.activateAppRow(index)
                        onContextMenuRequested: (item, index, x, y) => root.contextMenu(item, appList.model, index, x, y)
                    }

                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Up:
                            if (currentIndex <= 0) searchField.forceActiveFocus(Qt.BacktabFocusReason)
                            else decrementCurrentIndex()
                            break
                        case Qt.Key_Down: incrementCurrentIndex(); break
                        case Qt.Key_Left:
                        case Qt.Key_Backspace:
                            root.goBack(); break
                        case Qt.Key_Right:
                            if (currentItem && (currentItem.model.hasChildren ?? false)) root.activateAppRow(currentIndex)
                            break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            root.activateAppRow(currentIndex); break
                        case Qt.Key_Menu:
                            if (currentItem) root.contextMenu(currentItem, model, currentIndex); break
                        case Qt.Key_Tab:
                        case Qt.Key_Backtab:
                            root.focusNextSection(appList, event.key === Qt.Key_Backtab); break
                        default:
                            if (!root.forwardTyping(event)) return
                        }
                        event.accepted = true
                    }
                }
            }

            // -- search results (KRunner)
            ColumnLayout {
                anchors.fill: parent
                visible: root.mode === "search"
                spacing: Kirigami.Units.smallSpacing

                SectionLabel {
                    Layout.fillWidth: true
                    tk: root.tk
                    glyph: "◉"
                    text: i18n("Results")
                    info: launcher.runnerModel.querying ? i18n("searching …")
                        : String(resultsView.count).padStart(2, "0")
                }

                KItemModels.KSortFilterProxyModel {
                    id: resultsProxy
                    // re-evaluated whenever the runner model publishes results
                    sourceModel: launcher.runnerModel.count > 0 ? launcher.runnerModel.modelForRow(0) : null
                    filterRowCallback: (sourceRow, sourceParent) => sourceRow < root.maxResults
                    onSourceModelChanged: resultsView.currentIndex = 0
                }
                Connections {
                    target: launcher.runnerModel
                    function onQueryFinished() { resultsView.currentIndex = 0 }
                }

                ListView {
                    id: resultsView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: resultsProxy
                    currentIndex: 0
                    keyNavigationEnabled: true
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds
                    Accessible.role: Accessible.List
                    Accessible.name: i18n("Search results")
                    rightMargin: resultsViewBar.visible ? resultsViewBar.width : 0
                    PC3.ScrollBar.vertical: PC3.ScrollBar { id: resultsViewBar }

                    section.property: "group"
                    section.criteria: ViewSection.FullString
                    section.delegate: MonoLabel {
                        required property string section
                        tk: root.tk
                        width: ListView.view ? ListView.view.width : 100
                        topPadding: Kirigami.Units.smallSpacing
                        bottomPadding: 2
                        leftPadding: Kirigami.Units.smallSpacing * 2 + 2
                        text: section
                        color: root.tk.blue
                    }

                    delegate: ItemRow {
                        tk: root.tk
                        kind: "result"
                        showCurrent: true
                        onActivated: index => root.launchResult(index)
                        onContextMenuRequested: (item, index, x, y) => {
                            const src = resultsProxy.mapToSource(resultsProxy.index(index, 0))
                            root.contextMenu(item, resultsProxy, index, x, y, resultsProxy.sourceModel, src.row)
                        }
                    }

                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Up:
                            if (currentIndex <= 0) searchField.forceActiveFocus(Qt.BacktabFocusReason)
                            else decrementCurrentIndex()
                            break
                        case Qt.Key_Down: incrementCurrentIndex(); break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            root.launchResult(currentIndex); break
                        case Qt.Key_Tab:
                        case Qt.Key_Backtab:
                            root.focusNextSection(resultsView, event.key === Qt.Key_Backtab); break
                        default:
                            if (!root.forwardTyping(event)) return
                        }
                        event.accepted = true
                    }

                    PlasmaExtras.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.gridUnit * 4
                        visible: resultsView.count === 0 && !launcher.runnerModel.querying
                        iconName: "edit-none"
                        text: i18n("No matches")
                    }
                }
            }
        }

        // ---- footer -----------------------------------------------------------
        Divider {
            tk: root.tk
            Layout.fillWidth: true
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing * 2

            Rectangle {
                // user picture in a thin technical frame
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium + 4
                Layout.preferredHeight: Layout.preferredWidth
                color: "transparent"
                radius: root.tk.radiusControl
                border.width: 1
                border.color: root.tk.alpha(root.tk.border, 0.9)
                Kirigami.Icon {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: kuser.faceIconUrl.toString().length > 0 ? kuser.faceIconUrl : "user-identity"
                    fallback: "user-identity"
                }
            }
            Text {
                Layout.maximumWidth: root.width * 0.3
                // first name in lower case ("marc"), like the shell prompt
                text: (kuser.fullName.trim().split(/\s+/)[0] || kuser.loginName).toLowerCase()
                color: root.tk.text
                font.family: root.tk.uiFamily
                font.pointSize: root.tk.uiSize
                elide: Text.ElideRight
                textFormat: Text.PlainText
                PC3.ToolTip.text: kuser.fullName
            }
            Led {
                tk: root.tk
                color: root.tk.blue
                Layout.alignment: Qt.AlignVCenter
            }
            MonoLabel {
                tk: root.tk
                text: i18n("Online")
                color: root.tk.blue
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }

            // session actions from kicker's SystemModel (with confirmation by
            // the session manager where Plasma asks for it)
            RowLayout {
                id: powerRow
                spacing: 0
                readonly property var wanted: ["lock-screen", "logout", "suspend", "reboot", "shutdown"]

                function firstButton() {
                    for (let i = 0; i < powerRepeater.count; ++i) {
                        const b = powerRepeater.itemAt(i)
                        if (b && b.visible && b.enabled) return b
                    }
                    return null
                }
                function buttons() {
                    const r = []
                    for (let i = 0; i < powerRepeater.count; ++i) {
                        const b = powerRepeater.itemAt(i)
                        if (b && b.visible && b.enabled) r.push(b)
                    }
                    return r
                }
                function step(from, delta) {
                    const b = buttons()
                    const i = b.indexOf(from)
                    if (i + delta >= 0 && i + delta < b.length)
                        b[i + delta].forceActiveFocus(Qt.TabFocusReason)
                }

                Repeater {
                    id: powerRepeater
                    model: launcher.systemModel
                    delegate: PC3.ToolButton {
                        id: powerButton
                        required property int index
                        required property var model
                        visible: powerRow.wanted.indexOf(model.favoriteId) >= 0
                        enabled: !(model.disabled ?? false)
                        icon.name: model.decoration
                        text: model.display
                        display: PC3.AbstractButton.IconOnly
                        Accessible.name: model.display
                        PC3.ToolTip.text: model.display
                        PC3.ToolTip.visible: hovered || visualFocus
                        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                        onClicked: {
                            launcher.systemModel.trigger(index, "", null)
                            root.closePopup()
                        }
                        Keys.onLeftPressed: powerRow.step(powerButton, -1)
                        Keys.onRightPressed: powerRow.step(powerButton, 1)
                        Keys.onUpPressed: searchField.forceActiveFocus(Qt.BacktabFocusReason)
                        Keys.onTabPressed: root.focusNextSection(powerRow.firstButton(), false)
                        Keys.onBacktabPressed: root.focusNextSection(powerRow.firstButton(), true)
                        Keys.onReturnPressed: clicked()
                        Keys.onEnterPressed: clicked()
                    }
                }
            }
        }
    }
}
