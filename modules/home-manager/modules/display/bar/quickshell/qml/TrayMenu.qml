// One level of a system tray context menu. Used recursively via
// Loader { sourceComponent: ... Qt.createComponent("TrayMenu.qml") }
// so submenus, sub-submenus etc. all use the same delegate code.
//
// Positioning: every level (top + all submenus) anchors to the same
// root bar window. We compute absolute screen positions via
// mapToGlobal and convert back into the bar window's local space.
// That way chained PopupAnchors don't have to play coordinate-space
// gymnastics between nested popup windows.
import QtQuick
import Quickshell

PopupWindow {
    id: popup

    // The QsMenuHandle for THIS level. Set at show()/createObject.
    property var menuHandle: null

    // The bar PanelWindow that anchors the entire chain.
    property var rootWindow: null

    // Where this popup wants its top-left in *bar* coordinates.
    property real screenX: 0
    property real screenY: 0

    color: "transparent"
    visible: false
    grabFocus: !popup.parentLevel  // only the top-level grabs focus

    implicitWidth: 260
    implicitHeight: menuFrame.implicitHeight

    QsMenuOpener {
        id: opener
        menu: popup.menuHandle
    }

    // Parent in the chain (null for top-level). Used to bubble Hide.
    property var parentLevel: null

    // Which child submenu is currently spawned (one at a time per level).
    property var subInstance: null
    property var subForEntry: null

    anchor {
        window: popup.rootWindow
        rect.x: popup.screenX
        rect.y: popup.screenY
        rect.width: 1
        rect.height: 1
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
    }

    function show(item, anchorItem, window) {
        popup.menuHandle = item ? item.menu : null
        popup.rootWindow = window
        // Position top-level above the tray pill, horizontally centered.
        if (anchorItem && window) {
            const g = anchorItem.mapToItem(null, 0, 0)
            popup.screenX = g.x + anchorItem.width / 2 - popup.implicitWidth / 2
            popup.screenY = g.y - popup.implicitHeight - 4
        }
        popup.visible = true
    }

    // Called by an entry row when the user wants its submenu open.
    function openSubFor(entry, handle) {
        if (popup.subForEntry === entry && popup.subInstance) {
            return  // already open, no-op
        }
        // Close any existing one
        closeSub()

        const g = entry.mapToItem(null, 0, 0)
        const subX = g.x + entry.width + 2
        const subY = g.y - 6   // align roughly with row top inside its frame

        const c = Qt.createComponent(Qt.resolvedUrl("TrayMenu.qml"))
        if (c.status !== Component.Ready) {
            console.warn("TrayMenu submenu component not ready:", c.errorString())
            return
        }
        const sub = c.createObject(null, {
            rootWindow: popup.rootWindow,
            parentLevel: popup,
            screenX: subX,
            screenY: subY
        })
        sub.menuHandle = handle
        sub.visible = true
        popup.subInstance = sub
        popup.subForEntry = entry
    }

    function closeSub() {
        if (popup.subInstance) {
            popup.subInstance.closeSub()
            popup.subInstance.visible = false
            popup.subInstance.destroy()
            popup.subInstance = null
            popup.subForEntry = null
        }
    }

    function bubbleHide() {
        closeSub()
        visible = false
        if (parentLevel) parentLevel.bubbleHide()
        menuHandle = null
    }

    Rectangle {
        id: menuFrame
        anchors.fill: parent
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1
        implicitHeight: menuColumn.implicitHeight + 12

        Column {
            id: menuColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: opener.children

                delegate: Item {
                    id: entry
                    required property var modelData
                    width: menuColumn.width
                    implicitHeight: modelData && modelData.isSeparator ? 9 : 30

                    Rectangle {
                        visible: entry.modelData && entry.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: "#555"
                    }

                    Rectangle {
                        visible: entry.modelData && !entry.modelData.isSeparator
                        anchors.fill: parent
                        color: itemHover.containsMouse
                            ? Theme.activeBg
                            : (entry.modelData && entry.modelData.hasChildren
                                && popup.subForEntry === entry
                                    ? Qt.lighter(Theme.defaultBg, 1.3)
                                    : "transparent")
                        radius: Theme.innerRadius

                        Behavior on color {
                            ColorAnimation { duration: Theme.fadeMs / 2 }
                        }

                        Image {
                            id: rowIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            visible: entry.modelData && entry.modelData.icon !== ""
                            source: entry.modelData ? entry.modelData.icon : ""
                            sourceSize.width: 16
                            sourceSize.height: 16
                            smooth: true
                            mipmap: true
                        }

                        Text {
                            id: rowLabel
                            anchors.left: rowIcon.visible ? rowIcon.right : parent.left
                            anchors.leftMargin: rowIcon.visible ? 8 : 8
                            anchors.right: subArrow.visible ? subArrow.left : parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: entry.modelData ? entry.modelData.text : ""
                            color: !entry.modelData || !entry.modelData.enabled
                                ? Theme.mutedColor
                                : (itemHover.containsMouse ? Theme.activeTextColor : Theme.textColor)
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: itemHover.containsMouse
                            elide: Text.ElideRight
                        }

                        Text {
                            id: subArrow
                            visible: entry.modelData && entry.modelData.hasChildren
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▸"
                            color: itemHover.containsMouse ? Theme.activeTextColor : Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: itemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: entry.modelData
                                && entry.modelData.enabled
                                && !entry.modelData.isSeparator

                            onEntered: {
                                // Only switch / open a submenu when hovering a
                                // hasChildren row. Hovering leaf rows must NOT
                                // close an already-open submenu — otherwise the
                                // mouse sweeping from the parent row toward the
                                // submenu kills it.
                                if (entry.modelData.hasChildren) {
                                    popup.openSubFor(entry, entry.modelData)
                                }
                            }
                            onClicked: {
                                if (entry.modelData.hasChildren) {
                                    popup.openSubFor(entry, entry.modelData)
                                } else {
                                    entry.modelData.triggered()
                                    popup.bubbleHide()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
