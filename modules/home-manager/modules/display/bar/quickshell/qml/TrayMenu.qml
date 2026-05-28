// One level of a system tray context menu. Used recursively via
// Qt.createComponent(Qt.resolvedUrl("TrayMenu.qml")) so submenus,
// sub-submenus etc. all use the same delegate code.
//
// Anchoring:
// - The top level anchors to the BottomBar PanelWindow above the
//   tray pill (placement = "above").
// - Every submenu anchors to its IMMEDIATE PARENT popup window with
//   anchor coords in that popup's local scene (placement = "right").
//   This is what xdg_popup is designed for and avoids any
//   cross-window coordinate gymnastics.
import QtQuick
import Quickshell

PopupWindow {
    id: popup

    property var menuHandle: null
    property var anchorWindow: null
    property Item anchorItem: null
    property string placement: "above"   // "above" or "right"
    property var parentLevel: null

    color: "transparent"
    visible: false
    grabFocus: !popup.parentLevel        // only the root level grabs focus

    implicitWidth: 260
    implicitHeight: menuFrame.implicitHeight

    QsMenuOpener {
        id: opener
        menu: popup.menuHandle
    }

    property var subInstance: null
    property var subForEntry: null

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
            return p.y - popup.implicitHeight - 4
        }
        rect.width: 1
        rect.height: 1
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
    }

    function show(item, anchor, window) {
        popup.menuHandle = item ? item.menu : null
        popup.anchorItem = anchor
        popup.anchorWindow = window
        popup.placement = "above"
        popup.parentLevel = null
        popup.visible = true
    }

    function openSubFor(entry, handle) {
        if (popup.subForEntry === entry && popup.subInstance) return
        closeSub()

        const c = Qt.createComponent(Qt.resolvedUrl("TrayMenu.qml"))
        if (c.status !== Component.Ready) {
            console.warn("TrayMenu sub component error:", c.errorString())
            return
        }
        const sub = c.createObject(null, {
            menuHandle: handle,
            anchorWindow: popup,        // <- anchor to this popup window
            anchorItem: entry,
            placement: "right",
            parentLevel: popup
        })
        sub.visible = true
        popup.subInstance = sub
        popup.subForEntry = entry
    }

    function closeSub() {
        if (popup.subInstance) {
            popup.subInstance.bubbleHide()
            popup.subInstance.destroy()
            popup.subInstance = null
            popup.subForEntry = null
        }
    }

    function bubbleHide() {
        closeSub()
        popup.visible = false
        if (popup.parentLevel && popup.parentLevel.visible) {
            popup.parentLevel.bubbleHide()
        }
        popup.menuHandle = null
    }

    // Cascade: when this popup becomes hidden (e.g. root grabFocus
    // dismiss, or programmatic), drop our child too.
    onVisibleChanged: {
        if (!visible) closeSub()
    }

    Component.onDestruction: closeSub()

    Rectangle {
        id: menuFrame
        anchors.fill: parent
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1
        implicitHeight: menuColumn.implicitHeight + 12

        focus: true
        Keys.onEscapePressed: popup.bubbleHide()

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
                            anchors.leftMargin: 8
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
                                // Hovering a hasChildren row opens / switches
                                // the submenu. Hovering anything else leaves
                                // the open submenu alone so the mouse can
                                // sweep into it without it disappearing.
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
