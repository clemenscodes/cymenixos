// One level of a system tray context menu. Used recursively via
// Loader{ source: Qt.resolvedUrl("TrayMenu.qml") } so submenus, sub-
// submenus etc. all use the same delegate code.
import QtQuick
import Quickshell

PopupWindow {
    id: popup

    // The QsMenuHandle for THIS level. Set at show().
    property var menuHandle: null

    // What this popup is anchored to.
    property var anchorWindow: null
    property Item anchorItem: null

    // "below" → drop under the anchor (top-level menu under the tray pill)
    // "right" → flyout to the right of the anchor (submenu off a parent row)
    property string placement: "below"

    color: "transparent"
    visible: false
    grabFocus: placement === "below"

    implicitWidth: 260
    implicitHeight: menuFrame.implicitHeight

    QsMenuOpener {
        id: opener
        menu: popup.menuHandle
    }

    // Submenu state — only one submenu open at a time per level.
    property var subHandle: null
    property Item subAnchor: null

    anchor {
        window: popup.anchorWindow
        rect.x: {
            if (!popup.anchorItem) return 0
            const p = popup.anchorItem.mapToItem(null, 0, 0)
            if (popup.placement === "right") {
                return p.x + popup.anchorItem.width + 2
            }
            return p.x + popup.anchorItem.width / 2 - popup.implicitWidth / 2
        }
        rect.y: {
            if (!popup.anchorItem) return 0
            const p = popup.anchorItem.mapToItem(null, 0, 0)
            if (popup.placement === "right") {
                return p.y
            }
            // Top-level: drop the popup above the anchor (bottom-bar tray)
            return 0
        }
        rect.width: 1
        rect.height: 1
        edges: popup.placement === "right" ? Edges.Right : Edges.Top
        gravity: popup.placement === "right" ? Edges.Right : Edges.Top
    }

    function show(item, anchor, window) {
        popup.menuHandle = item ? item.menu : null
        popup.anchorItem = anchor
        popup.anchorWindow = window
        popup.placement = "below"
        popup.visible = true
    }

    function showSub(handle, anchor) {
        popup.subHandle = handle
        popup.subAnchor = anchor
    }

    function clearSub() {
        popup.subHandle = null
        popup.subAnchor = null
    }

    function hideAll() {
        popup.clearSub()
        popup.visible = false
        popup.menuHandle = null
    }

    // Lazy-load the submenu — it's literally this same TrayMenu.qml.
    Loader {
        id: subLoader
        active: popup.subHandle !== null
        sourceComponent: Component {
            id: subComp
            // Use a placeholder Item so the Loader can instantiate the
            // nested popup without referencing TrayMenu by name (which
            // would be a forward reference inside its own file).
            Item {
                Component.onCompleted: {
                    const c = Qt.createComponent(Qt.resolvedUrl("TrayMenu.qml"))
                    if (c.status === Component.Ready) {
                        const sub = c.createObject(null, {
                            anchorWindow: popup,
                            anchorItem: popup.subAnchor,
                            placement: "right"
                        })
                        sub.menuHandle = popup.subHandle
                        sub.visible = true
                        // expose so parent can chase it on hide
                        subLoader.subInstance = sub
                    }
                }
                Component.onDestruction: {
                    if (subLoader.subInstance) {
                        subLoader.subInstance.hideAll()
                        subLoader.subInstance.destroy()
                        subLoader.subInstance = null
                    }
                }
            }
        }
        property var subInstance: null
        onActiveChanged: {
            if (!active && subInstance) {
                subInstance.hideAll()
                subInstance.destroy()
                subInstance = null
            }
        }
    }

    // Walk up the parent chain hiding popups when an action fires.
    function bubbleHide() {
        if (anchorWindow && typeof anchorWindow.bubbleHide === "function") {
            anchorWindow.bubbleHide()
        }
        hideAll()
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

                    // Separator
                    Rectangle {
                        visible: entry.modelData && entry.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: "#555"
                    }

                    // Regular entry
                    Rectangle {
                        visible: entry.modelData && !entry.modelData.isSeparator
                        anchors.fill: parent
                        color: itemHover.containsMouse
                            ? Theme.activeBg
                            : (entry.modelData && entry.modelData.hasChildren
                                && popup.subHandle === entry.modelData
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

                        // Submenu indicator arrow
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
                                if (entry.modelData.hasChildren) {
                                    popup.showSub(entry.modelData, entry)
                                } else {
                                    popup.clearSub()
                                }
                            }
                            onClicked: {
                                if (entry.modelData.hasChildren) {
                                    popup.showSub(entry.modelData, entry)
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
