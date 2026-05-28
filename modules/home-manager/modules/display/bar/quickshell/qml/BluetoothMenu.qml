import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth

PanelWindow {
    id: menu

    readonly property int cardWidth: 420
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
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: menu.hide()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: menu.cardWidth
        implicitHeight: Math.min(menu.cardMaxHeight, layout.implicitHeight + 28)
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: { /* swallow */ }
        }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: menu.adapter && menu.adapter.enabled ? "" : ""
                    color: menu.adapter && menu.adapter.enabled ? Theme.activeBg : Theme.mutedColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 6
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Bluetooth"
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }

                    Text {
                        text: {
                            if (!menu.adapter) return "No adapter"
                            const n = menu.allDevices.filter(d => d.connected).length
                            const total = menu.allDevices.length
                            if (!menu.adapter.enabled) return "Adapter off"
                            if (menu.adapter.discovering) return "Scanning…  ·  " + total + " visible"
                            if (n === 0) return total + " known device" + (total === 1 ? "" : "s")
                            return n + " connected  ·  " + total + " known"
                        }
                        color: Qt.darker(Theme.textColor, 1.5)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 4
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 32
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

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.darker(Theme.textColor, 4)
            }

            Text {
                visible: menu.sortedDevices.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                text: menu.adapter && menu.adapter.enabled
                    ? "No known devices.\nPair via bluetoothctl or a settings app."
                    : "Adapter is off."
                color: Qt.darker(Theme.textColor, 1.5)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            ListView {
                id: deviceList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(360, count * 48)
                visible: menu.sortedDevices.length > 0
                clip: true
                spacing: 2
                model: menu.sortedDevices
                currentIndex: menu.selectedIndex

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 44
                    radius: Theme.innerRadius
                    color: (row.index === menu.selectedIndex || rowHover.containsMouse)
                        ? Qt.lighter(Theme.defaultBg, 1.4)
                        : Theme.defaultBg

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        IconImage {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            implicitSize: 22
                            source: Quickshell.iconPath(row.modelData.icon, "bluetooth")
                            smooth: true
                            mipmap: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.deviceName || row.modelData.name || row.modelData.address
                                color: Theme.textColor
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                font.bold: row.index === menu.selectedIndex
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.address + "  ·  "
                                    + (row.modelData.connected ? "connected"
                                        : (row.modelData.paired ? "paired" : "known"))
                                color: row.modelData.connected ? Theme.activeBg : Qt.darker(Theme.textColor, 1.6)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 5
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: row.modelData.connected ? "" : ""
                            color: row.modelData.connected ? Theme.activeBg : Qt.darker(Theme.textColor, 1.5)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            Layout.alignment: Qt.AlignVCenter
                        }
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

            Text {
                Layout.fillWidth: true
                visible: menu.adapter !== null
                text: menu.adapter && menu.adapter.discovering
                    ? "Scanning · click to stop"
                    : (menu.adapter && menu.adapter.enabled ? "Click to scan for new devices" : "")
                color: Qt.darker(Theme.textColor, 1.6)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 4
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: parent.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: menu.adapter !== null && menu.adapter.enabled
                    onClicked: { if (menu.adapter) menu.adapter.discovering = !menu.adapter.discovering }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Enter toggle · Space adapter · Esc"
                color: Qt.darker(Theme.textColor, 1.8)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 5
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
