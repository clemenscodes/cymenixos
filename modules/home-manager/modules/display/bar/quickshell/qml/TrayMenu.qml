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
    // "above" | "below" | "auto" — "auto" runs the spaceAbove/spaceBelow
    // heuristic. Bars know their own placement (bottom bar always wants
    // "above", top bar always "below"), so they pass it explicitly to
    // sidestep the mapToItem-on-layer-shell coordinate fragility.
    property string placement: "auto"

    // Anchor geometry in SCREEN coordinates. Captured in show(); the
    // card's x/y/height are bindings derived from these so the card
    // re-positions when its own height changes (e.g. when the
    // QsMenuOpener finishes populating).
    property real anchorScreenX: 0
    property real anchorScreenY: 0
    property real anchorWidth: 0
    property real anchorHeight: 0
    readonly property real screenWidth: anchorWindow && anchorWindow.screen
        ? anchorWindow.screen.width : 1920
    readonly property real screenHeight: anchorWindow && anchorWindow.screen
        ? anchorWindow.screen.height : 1080

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

    function show(item, anchor, window, placement) {
        trayMenu.trayItem = item
        trayMenu.anchorItem = anchor
        trayMenu.anchorWindow = window
        trayMenu.placement = placement || "auto"
        if (window && window.screen) trayMenu.screen = window.screen

        if (anchor && window && window.screen) {
            // mapToGlobal on items inside a Wayland layer-shell window
            // returns the item's position in the BAR window's scene,
            // not real screen coordinates. The bar is bottom-anchored
            // and fills width, so its screen-Y = screenHeight - barHeight,
            // screen-X = 0.
            const local = anchor.mapToItem(null, 0, 0)
            const barScreenY = window.screen.height - window.height
            trayMenu.anchorScreenX = local.x
            trayMenu.anchorScreenY = local.y + barScreenY
            trayMenu.anchorWidth = anchor.width
            trayMenu.anchorHeight = anchor.height
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

    readonly property int cardMinHeight: 80

    // Track the current SubMenu's content column height so the card
    // resizes when levelOpener.children populates asynchronously.
    readonly property int currentContentHeight: stack.currentItem
        && stack.currentItem.contentColumnHeight !== undefined
            ? stack.currentItem.contentColumnHeight
            : 0

    // Vertical space above and below the anchor, with an 8 px breathing
    // margin to the screen edges and 4 px gap to the anchor itself.
    readonly property real spaceAbove: anchorScreenY - 12
    readonly property real spaceBelow: screenHeight - (anchorScreenY + anchorHeight) - 12
    readonly property bool placeAbove: placement === "above"
        ? true
        : placement === "below"
            ? false
            : spaceAbove >= spaceBelow
    readonly property real barHeight: anchorWindow ? anchorWindow.height : 60
    readonly property real availableHeight: placement === "above"
        ? screenHeight - barHeight - 12
        : placement === "below"
            ? screenHeight - barHeight - 12
            : (placeAbove ? spaceAbove : spaceBelow)

    Rectangle {
        id: card
        readonly property int cardWidth: 280
        width: cardWidth
        x: Math.max(8, Math.min(
            trayMenu.anchorScreenX + trayMenu.anchorWidth / 2 - cardWidth / 2,
            trayMenu.screenWidth - cardWidth - 8))
        // For explicit "above" placement we don't trust anchorScreenY
        // (mapToItem(null, ...) inside a layer-shell window has bitten us
        // before): anchor the card to the bottom edge of the screen
        // above the bar's exclusive zone. Same for "below" from a top
        // bar. "auto" still uses the anchor-relative path.
        y: trayMenu.placement === "above"
            ? trayMenu.screenHeight - (trayMenu.anchorWindow ? trayMenu.anchorWindow.height : 60) - height - 4
            : trayMenu.placement === "below"
                ? (trayMenu.anchorWindow ? trayMenu.anchorWindow.height : 60) + 4
                : trayMenu.placeAbove
                    ? trayMenu.anchorScreenY - height - 4
                    : trayMenu.anchorScreenY + trayMenu.anchorHeight + 4
        height: Math.max(trayMenu.cardMinHeight,
                         Math.min(trayMenu.availableHeight,
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
