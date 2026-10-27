pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami

// APERTURE LAUNCHER: application launcher for Aperture OS.
//
// Uses the same models as Kickoff (org.kde.plasma.private.kicker):
//  - RootModel                 categories ("Alle Anwendungen", Entwicklung, …)
//  - RootModel.favoritesModel  KAStats favourites (same store as Kickoff)
//  - RunnerModel               KRunner search
//  - SystemModel               lock / logout / suspend / reboot / shutdown
// Provides "org.kde.plasma.launchermenu", so the Meta key opens it.
PlasmoidItem {
    id: launcher

    Tokens { id: tokens }
    readonly property alias tk: tokens

    readonly property bool reduceMotion: Plasmoid.configuration.reduceMotion || tokens.reduceMotionDefault
    readonly property int fadeDuration: reduceMotion ? 0 : tokens.motionFast
    readonly property bool inPanel: [PlasmaCore.Types.TopEdge, PlasmaCore.Types.RightEdge,
        PlasmaCore.Types.BottomEdge, PlasmaCore.Types.LeftEdge].includes(Plasmoid.location)
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property string favoritesClient: Plasmoid.configuration.favoritesClientId.length > 0
        ? Plasmoid.configuration.favoritesClientId
        : "aperture-os.launcher.favorites"

    // ---- models -----------------------------------------------------------
    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        autoPopulate: false
        appletInterface: launcher
        appNameFormat: 0              // name only
        flat: true                    // categories without sub-categories
        sorted: true
        showSeparators: false
        showTopLevelItems: true
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        highlightNewlyInstalledApps: false

        Component.onCompleted: {
            favoritesModel.initForClient(launcher.favoritesClient)
        }
    }
    onFavoritesClientChanged: rootModel.favoritesModel.initForClient(favoritesClient)

    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        appletInterface: launcher
        mergeResults: true
        favoritesModel: launcher.rootModel.favoritesModel
        query: launcher.searchText
        onRequestUpdateQuery: query => launcher.searchText = query
    }

    readonly property Kicker.SystemModel systemModel: Kicker.SystemModel {
        favoritesModel: launcher.rootModel.systemFavoritesModel
    }

    Kicker.ProcessRunner { id: processRunner }

    // set by the search field; drives the runner query
    property string searchText: ""
    onSearchTextChanged: hoverActive = false

    // Hover only moves the selection after the pointer really moved: content
    // that appears under a resting pointer must not steal the keyboard
    // selection (search results, category switch).
    property bool hoverActive: false
    property point lastHoverPos: Qt.point(-1, -1)
    function hoverMoved(item, x, y) {
        const p = item.mapToGlobal(x, y)
        const moved = lastHoverPos.x >= 0 && (p.x !== lastHoverPos.x || p.y !== lastHoverPos.y)
        lastHoverPos = p
        if (moved)
            hoverActive = true
        return moved
    }

    // ---- representations ---------------------------------------------------
    Plasmoid.icon: Plasmoid.configuration.icon || "aperture-os"
    toolTipMainText: i18n("Aperture Launcher")
    toolTipSubText: i18n("Launch and search applications")

    preferredRepresentation: compactRepresentation
    hideOnWindowDeactivate: true

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 18

    compactRepresentation: MouseArea {
        id: compactRoot
        hoverEnabled: true
        activeFocusOnTab: true

        readonly property int iconSize: Kirigami.Units.iconSizes.large
        implicitWidth: iconSize
        implicitHeight: iconSize
        Layout.minimumWidth: launcher.vertical ? -1 : height
        Layout.minimumHeight: launcher.vertical ? width : -1

        Accessible.name: Plasmoid.title
        Accessible.role: Accessible.Button

        property bool wasExpanded: false
        onPressed: wasExpanded = launcher.expanded
        onClicked: launcher.expanded = !wasExpanded
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                launcher.expanded = !launcher.expanded
                event.accepted = true
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compactRoot.containsMouse || launcher.expanded
            roundToIconSize: true
        }
    }

    fullRepresentation: FullRepresentation {
        focus: true
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications …")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: Plasmoid.activationTogglesExpanded = true
}
