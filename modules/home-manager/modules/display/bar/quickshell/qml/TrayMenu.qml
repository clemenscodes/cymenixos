// Tray context menu — uses Quickshell's native QsMenuAnchor so submenus
// of arbitrary depth render reliably via Qt's platform menu. Styling
// of the menu itself happens at the application level in shell.qml:
//   - Fusion style forced via `pragma Env QT_STYLE_OVERRIDE=Fusion`
//   - QPalette + application font overridden in Component.onCompleted
//     so QMenu picks them up and matches the bar's purple/pink theme.
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
