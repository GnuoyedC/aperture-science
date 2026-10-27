pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.extras as PlasmaExtras

// Context menu for an entry: the model's own actions (e.g. "Bearbeiten …",
// jump list entries) plus "Zu Favoriten hinzufügen / entfernen".
// `trigger(actionId, argument)` is supplied by the caller and must call
// model.trigger(row, actionId, argument) on the right source model.
Item {
    id: root

    property var actionList: null
    property var trigger: null        // function(actionId, actionArgument) -> bool
    signal closeRequested()

    visible: false

    function open(item, actions, x, y, triggerFn) {
        root.trigger = triggerFn
        root.actionList = actions
        menu.visualParent = item
        if (x !== undefined && y !== undefined)
            menu.open(x, y)
        else
            menu.openRelative()
    }

    function favoriteActions(favoriteModel, favoriteId) {
        if (!favoriteModel || !favoriteId || !favoriteModel.enabled)
            return []
        if (favoriteModel.isFavorite(favoriteId))
            return [{ text: i18n("Remove from Favorites"), icon: "bookmark-remove",
                      actionId: "_kicker_favorite_remove",
                      actionArgument: { favoriteModel: favoriteModel, favoriteId: favoriteId } }]
        return [{ text: i18n("Add to Favorites"), icon: "bookmark-new",
                  actionId: "_kicker_favorite_add",
                  actionArgument: { favoriteModel: favoriteModel, favoriteId: favoriteId } }]
    }

    // Merges the model's action list and the favourite action; nested
    // sub-menus (activities) are flattened away.
    function buildActions(model, favoriteModel) {
        let actions = model.hasActionList && model.actionList ? Array.from(model.actionList) : []
        actions = actions.filter(a => a && !a.subActions)
        const fav = favoriteActions(favoriteModel, model.favoriteId)
        if (fav.length > 0) {
            if (actions.length > 0)
                actions.push({ type: "separator" })
            actions = actions.concat(fav)
        }
        return actions
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: null
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }

    Instantiator {
        active: root.actionList !== null
        model: root.actionList
        delegate: PlasmaExtras.MenuItem {
            required property var modelData
            text: modelData.text ?? ""
            enabled: modelData.type !== "title" && (modelData.enabled ?? true)
            separator: modelData.type === "separator"
            section: modelData.type === "title"
            icon: modelData.icon ?? null
            onClicked: {
                const id = modelData.actionId ?? ""
                const arg = modelData.actionArgument
                if (id === "_kicker_favorite_add") {
                    arg.favoriteModel.addFavorite(arg.favoriteId)
                } else if (id === "_kicker_favorite_remove") {
                    arg.favoriteModel.removeFavorite(arg.favoriteId)
                } else if (id === "_aperture_fav_move") {
                    arg.fav.moveRow(arg.from, arg.to)
                } else if (root.trigger && root.trigger(id, arg)) {
                    root.closeRequested()
                }
            }
        }
        onObjectAdded: (index, object) => menu.addMenuItem(object)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }
}
