// Styled tray context menu using the caelestia / hybar pattern:
// a single overlay PanelWindow containing a StackView. Each level is
// a SubMenu Column with its OWN QsMenuOpener bound to its OWN handle.
// Drill-down by stack.push(); Back row at the top calls stack.pop().
//
// No nested PopupWindows — sidesteps every Hyprland xdg_popup chain
// issue (Hyprland #6682/#8020, Quickshell #589/#678/#794).
import QtQuick
import QtQuick.Controls
import Quickshell

PanelWindow {
    id: trayMenu

    property var trayItem: null
    property Item anchorItem: null
    property var anchorWindow: null

    property real menuX: 0
    property real menuY: 0

    visible: false
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: 0
    aboveWindows: true
    focusable: true

    function show(item, anchor, window) {
        trayMenu.trayItem = item
        trayMenu.anchorItem = anchor
        trayMenu.anchorWindow = window
        if (window && window.screen) trayMenu.screen = window.screen

        if (anchor && window) {
            const g = anchor.mapToItem(null, 0, 0)
            // Centre the menu horizontally on the tray icon, sit it just
            // above the bar with a small gap.
            const w = 280
            trayMenu.menuX = Math.max(8, g.x + anchor.width / 2 - w / 2)
            trayMenu.menuY = Math.max(8, g.y - 4 - 320)
        }

        // Reset the stack to the root menu of this tray item.
        stack.clear()
        stack.push(subMenuComp, {
            handle: item ? item.menu : null,
            isSubMenu: false
        })
        trayMenu.visible = true
        Qt.callLater(() => keyHandler.forceActiveFocus())
    }

    function hide() {
        trayMenu.visible = false
        stack.clear()
        trayMenu.trayItem = null
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: trayMenu.hide()

        // Click outside the card dismisses
        MouseArea {
            anchors.fill: parent
            onClicked: trayMenu.hide()
        }
    }

    Rectangle {
        id: card
        x: trayMenu.menuX
        y: trayMenu.menuY
        width: 280
        height: Math.min(540, stack.implicitHeight + 12)
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: { /* swallow */ }
        }

        StackView {
            id: stack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            height: Math.min(528, currentItem ? currentItem.implicitHeight : 0)
            implicitHeight: currentItem ? currentItem.implicitHeight : 0
            clip: true

            pushEnter: Transition {
                NumberAnimation { property: "x"; from: stack.width; to: 0; duration: 150 }
            }
            pushExit: Transition {
                NumberAnimation { property: "x"; from: 0; to: -stack.width; duration: 150 }
            }
            popEnter: Transition {
                NumberAnimation { property: "x"; from: -stack.width; to: 0; duration: 150 }
            }
            popExit: Transition {
                NumberAnimation { property: "x"; from: 0; to: stack.width; duration: 150 }
            }
        }
    }

    // -----------------------------------------------------------------
    // SubMenu component — one level of the menu chain. Has its OWN
    // QsMenuOpener bound to its OWN handle.
    // -----------------------------------------------------------------
    Component {
        id: subMenuComp

        Column {
            id: subMenu
            required property var handle
            required property bool isSubMenu

            spacing: 2
            width: 268

            QsMenuOpener {
                id: levelOpener
                menu: subMenu.handle
            }

            // ----- Back row, only on submenus -----
            Item {
                visible: subMenu.isSubMenu
                width: parent.width
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
                        onClicked: stack.pop()
                    }
                }
            }

            Rectangle {
                visible: subMenu.isSubMenu
                width: parent.width
                height: visible ? 1 : 0
                color: "#555"
            }

            // ----- Menu items -----
            Repeater {
                model: levelOpener.children

                delegate: Item {
                    id: entry
                    required property var modelData
                    width: subMenu.width
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
                        color: itemHover.containsMouse ? Theme.activeBg : "transparent"
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
                                    stack.push(subMenuComp, {
                                        handle: entry.modelData,
                                        isSubMenu: true
                                    })
                                } else {
                                    entry.modelData.triggered()
                                    trayMenu.hide()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
