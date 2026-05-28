import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth

PanelWindow {
    id: menu

    readonly property int cardWidth: 440
    readonly property int cardMaxHeight: 560

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var allDevices: Bluetooth.devices ? Bluetooth.devices.values : []

    readonly property var sortedDevices: {
        const arr = menu.allDevices.slice()
        arr.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return (a.deviceName || a.address).localeCompare(b.deviceName || b.address)
        })
        return arr
    }

    property int selectedIndex: 0

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

    function toggle(window) {
        if (menu.visible) menu.hide()
        else menu.show(window)
    }

    function show(window) {
        if (window && window.screen) menu.screen = window.screen
        menu.selectedIndex = 0
        menu.visible = true
        Qt.callLater(() => keyHandler.forceActiveFocus())
    }

    function hide() {
        menu.visible = false
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            const last = menu.sortedDevices.length - 1
            if (event.key === Qt.Key_Escape) {
                menu.hide()
                event.accepted = true
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === Qt.Key_Tab) {
                if (last >= 0) menu.selectedIndex = Math.min(last, menu.selectedIndex + 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === Qt.Key_Backtab) {
                if (last >= 0) menu.selectedIndex = Math.max(0, menu.selectedIndex - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (menu.selectedIndex >= 0 && menu.selectedIndex < menu.sortedDevices.length) {
                    const d = menu.sortedDevices[menu.selectedIndex]
                    d.connected = !d.connected
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Space) {
                if (menu.adapter) menu.adapter.enabled = !menu.adapter.enabled
                event.accepted = true
            } else if (event.key === Qt.Key_R) {
                if (menu.adapter && menu.adapter.enabled) menu.adapter.discovering = !menu.adapter.discovering
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: menu.hide()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: menu.cardWidth
        height: Math.min(menu.cardMaxHeight, cardColumn.implicitHeight + 28)
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: { /* swallow */ }
        }

        Column {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            // ----- Header row -----
            Item {
                width: parent.width
                height: 48

                Text {
                    id: headerIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.adapter && menu.adapter.enabled ? "" : ""
                    color: menu.adapter && menu.adapter.enabled ? Theme.activeBg : Theme.mutedColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 10
                }

                Text {
                    id: headerTitle
                    anchors.left: headerIcon.right
                    anchors.leftMargin: 14
                    anchors.top: parent.top
                    anchors.topMargin: 6
                    text: "Bluetooth"
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Text {
                    anchors.left: headerIcon.right
                    anchors.leftMargin: 14
                    anchors.top: headerTitle.bottom
                    anchors.topMargin: 2
                    text: {
                        if (!menu.adapter) return "No adapter detected"
                        if (!menu.adapter.enabled) return "Adapter off  ·  Space to toggle"
                        const n = menu.allDevices.filter(d => d.connected).length
                        const total = menu.allDevices.length
                        if (menu.adapter.discovering) return "Scanning…  ·  " + total + " visible"
                        if (n === 0) return total + " known device" + (total === 1 ? "" : "s")
                        return n + " connected  ·  " + total + " known"
                    }
                    color: Qt.darker(Theme.textColor, 1.5)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                }

                Rectangle {
                    id: powerBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 96
                    height: 32
                    radius: Theme.innerRadius
                    color: powerHover.containsMouse
                        ? Qt.lighter(menu.adapter && menu.adapter.enabled ? Theme.activeBg : Theme.defaultBg, 1.3)
                        : (menu.adapter && menu.adapter.enabled ? Theme.activeBg : Qt.lighter(Theme.defaultBg, 1.3))

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: menu.adapter && menu.adapter.enabled ? "ON" : "OFF"
                        color: menu.adapter && menu.adapter.enabled ? Theme.activeTextColor : Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        font.bold: true
                    }

                    MouseArea {
                        id: powerHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: menu.adapter !== null
                        onClicked: { if (menu.adapter) menu.adapter.enabled = !menu.adapter.enabled }
                    }
                }
            }

            // ----- Separator -----
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.darker(Theme.textColor, 4)
            }

            // ----- Empty state -----
            Text {
                visible: menu.sortedDevices.length === 0
                width: parent.width
                height: visible ? 60 : 0
                text: !menu.adapter
                    ? "No Bluetooth adapter found"
                    : (menu.adapter.enabled
                        ? "No known devices yet.\nPress R to scan, or pair via bluetoothctl."
                        : "Adapter is off. Press Space to turn it on.")
                color: Qt.darker(Theme.textColor, 1.5)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }

            // ----- Device list -----
            Column {
                visible: menu.sortedDevices.length > 0
                width: parent.width
                spacing: 2

                Repeater {
                    model: menu.sortedDevices

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 52
                        radius: Theme.innerRadius
                        color: (row.index === menu.selectedIndex || rowHover.containsMouse)
                            ? Qt.lighter(Theme.defaultBg, 1.4)
                            : Theme.defaultBg

                        Behavior on color {
                            ColorAnimation { duration: Theme.fadeMs / 2 }
                        }

                        IconImage {
                            id: rowIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 24
                            source: Quickshell.iconPath(row.modelData.icon, "bluetooth")
                            smooth: true
                            mipmap: true
                        }

                        Text {
                            id: rowName
                            anchors.left: rowIcon.right
                            anchors.leftMargin: 12
                            anchors.right: rowStatus.left
                            anchors.rightMargin: 12
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            text: row.modelData.deviceName || row.modelData.name || row.modelData.address
                            color: Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: row.index === menu.selectedIndex
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.left: rowIcon.right
                            anchors.leftMargin: 12
                            anchors.top: rowName.bottom
                            anchors.topMargin: 2
                            text: row.modelData.address + "  ·  "
                                + (row.modelData.connected ? "connected"
                                    : (row.modelData.paired ? "paired" : "known"))
                            color: row.modelData.connected ? Theme.activeBg : Qt.darker(Theme.textColor, 1.6)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 5
                        }

                        Text {
                            id: rowStatus
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.connected ? "" : ""
                            color: row.modelData.connected ? Theme.activeBg : Theme.mutedColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: menu.selectedIndex = row.index
                            onClicked: row.modelData.connected = !row.modelData.connected
                        }
                    }
                }
            }

            // ----- Scan toggle -----
            Item {
                width: parent.width
                height: scanText.implicitHeight + 8
                visible: menu.adapter !== null && menu.adapter.enabled

                Text {
                    id: scanText
                    anchors.centerIn: parent
                    text: menu.adapter && menu.adapter.discovering
                        ? "Scanning… click to stop"
                        : "Click to scan for new devices"
                    color: scanArea.containsMouse
                        ? Theme.activeBg
                        : Qt.darker(Theme.textColor, 1.5)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    font.underline: scanArea.containsMouse
                }

                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (menu.adapter) menu.adapter.discovering = !menu.adapter.discovering }
                }
            }

            // ----- Footer hint -----
            Text {
                width: parent.width
                text: "Enter toggle  ·  Space adapter  ·  R scan  ·  Esc"
                color: Qt.darker(Theme.textColor, 1.8)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 5
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
