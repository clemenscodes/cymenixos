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

        if (anchor && window && window.screen) {
            // mapToGlobal on items inside a Wayland layer-shell window
            // returns the item's position in the BAR window's scene,
            // not real screen coordinates. To get the screen position
            // we add the bar's own screen offset. The bar fills width
            // (screen-X 0) and is anchored to the bottom of the screen,
            // so its screen-Y = screenHeight - barHeight.
            const local = anchor.mapToItem(null, 0, 0)
            const screenW = window.screen.width
            const screenH = window.screen.height
            const barH = window.height
            const barScreenY = screenH - barH

            const ax = local.x        // bar spans width, screen-X 0
            const ay = local.y + barScreenY

            const cardWidth = 280
            const cardHeight = 320
            trayMenu.menuX = Math.max(8, Math.min(
                ax + anchor.width / 2 - cardWidth / 2,
                screenW - cardWidth - 8
            ))
            // Above the anchor if there is room, else flip below.
            const above = ay - cardHeight - 4
            const below = ay + anchor.height + 4
            trayMenu.menuY = above >= 8 ? above : below
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

    // Cap at screen-height minus the bar minus a small breathing margin
    // so the card never spills past the screen edge, but otherwise grow
    // as tall as the content needs.
    readonly property int cardMaxHeight: anchorWindow && anchorWindow.screen
        ? anchorWindow.screen.height - anchorWindow.height - 24
        : 1200
    readonly property int cardMinHeight: 80

    // Track the current SubMenu's content column height so the card
    // resizes when levelOpener.children populates asynchronously.
    readonly property int currentContentHeight: stack.currentItem
        && stack.currentItem.contentColumnHeight !== undefined
            ? stack.currentItem.contentColumnHeight
            : 0

    Rectangle {
        id: card
        x: trayMenu.menuX
        y: trayMenu.menuY
        width: 280
        height: Math.max(trayMenu.cardMinHeight,
                         Math.min(trayMenu.cardMaxHeight,
                                  trayMenu.currentContentHeight + 12))
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
            anchors.fill: parent
            anchors.margins: 6
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

        Flickable {
            id: subMenu
            required property var handle
            required property bool isSubMenu

            // Expose contentColumn height so the parent card can size
            // itself once the QsMenuOpener has populated children.
            readonly property int contentColumnHeight: contentColumn.implicitHeight

            implicitWidth: 268
            contentWidth: width
            contentHeight: contentColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            QsMenuOpener {
                id: levelOpener
                menu: subMenu.handle
            }

            Column {
                id: contentColumn
                width: subMenu.width
                spacing: 2

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
                        width: contentColumn.width
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
}
