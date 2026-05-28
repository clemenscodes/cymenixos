// Tray context menu. Hierarchical menus are rendered using a
// drill-down (replace) pattern in a single popup window: clicking a
// row with hasChildren swaps the popup's content for that row's
// children and adds a "← Back" entry on top. Clicking that back-
// entry pops the navigation stack. This avoids every cross-popup
// xdg_popup coordinate-space problem we had with flyout submenus,
// and works reliably under Hyprland.
import QtQuick
import Quickshell

PopupWindow {
    id: popup

    property var trayItem: null
    property Item anchorItem: null
    property var anchorWindow: null

    // Navigation stack: array of QsMenuHandle, deepest first.
    // The top-level menu is the trayItem.menu; we always derive the
    // currently-shown handle from this stack.
    property var stack: []

    readonly property var currentHandle: stack.length > 0
        ? stack[stack.length - 1]
        : (trayItem ? trayItem.menu : null)

    color: "transparent"
    grabFocus: true
    visible: false

    implicitWidth: 280
    implicitHeight: menuFrame.implicitHeight

    QsMenuOpener {
        id: opener
        menu: popup.currentHandle
    }

    anchor {
        window: popup.anchorWindow
        rect.x: popup.anchorItem
            ? popup.anchorItem.mapToItem(null, 0, 0).x
                + popup.anchorItem.width / 2 - popup.implicitWidth / 2
            : 0
        rect.y: popup.anchorItem
            ? popup.anchorItem.mapToItem(null, 0, 0).y - popup.implicitHeight - 4
            : 0
        rect.width: 1
        rect.height: 1
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
    }

    function show(item, anchor, window) {
        popup.trayItem = item
        popup.anchorItem = anchor
        popup.anchorWindow = window
        popup.stack = []
        popup.visible = true
    }

    function hide() {
        popup.visible = false
        popup.stack = []
        popup.trayItem = null
    }

    function pushHandle(handle) {
        const s = popup.stack.slice()
        s.push(handle)
        popup.stack = s
    }

    function popHandle() {
        if (popup.stack.length === 0) return
        const s = popup.stack.slice()
        s.pop()
        popup.stack = s
    }

    Rectangle {
        id: menuFrame
        anchors.fill: parent
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1
        implicitHeight: menuColumn.implicitHeight + 12

        focus: true
        Keys.onEscapePressed: popup.hide()

        Column {
            id: menuColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            // ----- Back row, shown only when we've drilled down -----
            Item {
                visible: popup.stack.length > 0
                width: menuColumn.width
                height: visible ? 30 : 0

                Rectangle {
                    anchors.fill: parent
                    color: backHover.containsMouse
                        ? Qt.lighter(Theme.defaultBg, 1.4)
                        : "transparent"
                    radius: Theme.innerRadius

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "← Back"
                        color: backHover.containsMouse ? Theme.activeTextColor : Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: backHover.containsMouse
                    }

                    MouseArea {
                        id: backHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.popHandle()
                    }
                }
            }

            // ----- Separator after Back -----
            Rectangle {
                visible: popup.stack.length > 0
                width: menuColumn.width
                height: visible ? 1 : 0
                color: "#555"
            }

            // ----- Menu items -----
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
                            : "transparent"
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
                            onClicked: {
                                if (entry.modelData.hasChildren) {
                                    popup.pushHandle(entry.modelData)
                                } else {
                                    entry.modelData.triggered()
                                    popup.hide()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
