// Styled tray context menu using a Miller-column (column-stack)
// pattern: a SINGLE popup window with multiple menu columns laid out
// side-by-side. Hovering / clicking a row with hasChildren drops any
// deeper columns and spawns a new one to its right. No nested
// PopupWindows — sidesteps every xdg_popup chain bug we hit with the
// previous attempts.
import QtQuick
import Quickshell

PopupWindow {
    id: popup

    property var trayItem: null
    property Item anchorItem: null
    property var anchorWindow: null

    // Stack of QsMenuHandle (not including the root menu, which is
    // trayItem.menu). drillTo() pushes/replaces entries here.
    property var subStack: []

    readonly property var rootMenu: trayItem ? trayItem.menu : null
    readonly property var levels: {
        const arr = []
        if (rootMenu) arr.push(rootMenu)
        for (let i = 0; i < subStack.length; i++) arr.push(subStack[i])
        return arr
    }

    readonly property int columnWidth: 240
    readonly property int columnGap: 6
    readonly property int columnsCount: levels.length
    readonly property int contentMargin: 6

    color: "transparent"
    grabFocus: true
    visible: false

    implicitWidth: columnsCount > 0
        ? columnsCount * columnWidth + (columnsCount - 1) * columnGap + contentMargin * 2
        : columnWidth + contentMargin * 2
    implicitHeight: menuFrame.implicitHeight

    function show(item, anchor, window) {
        popup.trayItem = item
        popup.anchorItem = anchor
        popup.anchorWindow = window
        popup.subStack = []
        popup.visible = true
    }

    function hide() {
        popup.visible = false
        popup.subStack = []
        popup.trayItem = null
    }

    // Drop everything deeper than `level` and push `handle` at that
    // position. level=0 means "first submenu off the root column".
    function drillTo(level, handle) {
        if (level < 0) return
        const arr = popup.subStack.slice(0, level)
        arr.push(handle)
        popup.subStack = arr
    }

    function trimTo(level) {
        if (popup.subStack.length <= level) return
        popup.subStack = popup.subStack.slice(0, level)
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

    Rectangle {
        id: menuFrame
        anchors.fill: parent
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1
        implicitHeight: levelsRow.implicitHeight + popup.contentMargin * 2

        focus: true
        Keys.onEscapePressed: popup.hide()

        Row {
            id: levelsRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: popup.contentMargin
            spacing: popup.columnGap

            Repeater {
                model: popup.levels

                delegate: Item {
                    id: levelDelegate
                    required property var modelData
                    required property int index

                    width: popup.columnWidth
                    implicitHeight: levelColumn.implicitHeight + 8
                    height: implicitHeight

                    QsMenuOpener {
                        id: opener
                        menu: levelDelegate.modelData
                    }

                    Column {
                        id: levelColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 4
                        spacing: 2

                        Repeater {
                            model: opener.children

                            delegate: Item {
                                id: entry
                                required property var modelData
                                required property int index

                                width: levelColumn.width
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
                                    radius: Theme.innerRadius
                                    color: {
                                        if (itemHover.containsMouse) return Theme.activeBg
                                        // Highlight the row whose child column is currently open
                                        if (entry.modelData && entry.modelData.hasChildren
                                            && popup.subStack.length > levelDelegate.index
                                            && popup.subStack[levelDelegate.index] === entry.modelData) {
                                            return Qt.lighter(Theme.defaultBg, 1.3)
                                        }
                                        return "transparent"
                                    }

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
                                            if (entry.modelData.hasChildren) {
                                                popup.drillTo(levelDelegate.index, entry.modelData)
                                            } else {
                                                // Trim deeper columns if user moves to a leaf
                                                // in a shallower column, so the cascade closes.
                                                popup.trimTo(levelDelegate.index)
                                            }
                                        }
                                        onClicked: {
                                            if (entry.modelData.hasChildren) {
                                                popup.drillTo(levelDelegate.index, entry.modelData)
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

                    // Visual divider between columns
                    Rectangle {
                        visible: levelDelegate.index < popup.columnsCount - 1
                        anchors.right: parent.right
                        anchors.rightMargin: -popup.columnGap / 2
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Qt.darker(Theme.defaultBg, 1.3)
                    }
                }
            }
        }
    }
}
