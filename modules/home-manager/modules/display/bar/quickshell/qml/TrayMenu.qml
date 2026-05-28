// Tray context menu using Quickshell's native QsMenuAnchor. We
// previously tried two custom-styled approaches (flyout submenus +
// drill-down replace), both of which fell over on the xdg_popup
// chain logic. QsMenuAnchor delegates rendering to Qt's platform
// menu, which is ugly (no theme matching) but reliably renders
// submenus of arbitrary depth and dismisses correctly.
import QtQuick
import Quickshell

QsMenuAnchor {
    id: trayMenu

    property Item anchorItem: null
    property var anchorWindow: null

    function show(item, target, window) {
        trayMenu.anchorItem = target
        trayMenu.anchorWindow = window
        trayMenu.menu = item ? item.menu : null
        trayMenu.open()
    }

    function hide() {
        trayMenu.close()
    }

    anchor {
        window: trayMenu.anchorWindow
        rect.x: trayMenu.anchorItem
            ? trayMenu.anchorItem.mapToItem(null, 0, 0).x + trayMenu.anchorItem.width / 2
            : 0
        rect.y: trayMenu.anchorItem
            ? trayMenu.anchorItem.mapToItem(null, 0, 0).y
            : 0
        rect.width: 1
        rect.height: 1
        edges: Edges.Top
        gravity: Edges.Top
    }
}
