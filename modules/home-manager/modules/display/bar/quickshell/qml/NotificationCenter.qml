// Notification history panel — a right-edge drawer listing every tracked
// notification, newest first, with a DND toggle and clear-all. Toggled
// from the bar pill or `qs ipc call notifs toggle`.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Notifications

PanelWindow {
    id: center

    readonly property int cardWidth: 440

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
        if (center.visible) center.hide()
        else center.show(window)
    }

    function show(window) {
        if (window && window.screen) center.screen = window.screen
        center.visible = true
        Qt.callLater(() => keyHandler.forceActiveFocus())
    }

    function hide() {
        center.visible = false
    }

    readonly property var items: Notifs.list
        ? Notifs.list.values.slice().reverse()
        : []

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        // Escape closes; C or Delete clears all notifications.
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                center.hide()
                event.accepted = true
            } else if (event.key === Qt.Key_C || event.key === Qt.Key_Delete) {
                Notifs.clearAll()
                event.accepted = true
            }
        }

        // Click outside the card dismisses.
        MouseArea {
            anchors.fill: parent
            onClicked: center.hide()
        }
    }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 12
        width: center.cardWidth
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        // Slide in from the right.
        transform: Translate {
            x: center.visible ? 0 : center.cardWidth + 24
            Behavior on x {
                NumberAnimation { duration: Theme.fadeMs; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: { /* swallow */ }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    font.bold: true
                }

                // DND toggle
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 30
                    radius: Theme.innerRadius
                    color: Notifs.dnd
                        ? Theme.urgentBg
                        : (dndHover.containsMouse ? Qt.lighter(Theme.defaultBg, 1.4) : Qt.lighter(Theme.defaultBg, 1.2))

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Notifs.dnd ? "🔕" : "🔔"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }

                    MouseArea {
                        id: dndHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.toggleDnd()
                    }
                }

                // Clear all
                Rectangle {
                    Layout.preferredWidth: clearLabel.implicitWidth + 20
                    Layout.preferredHeight: 30
                    radius: Theme.innerRadius
                    visible: center.items.length > 0
                    color: clearHover.containsMouse ? Qt.lighter(Theme.defaultBg, 1.4) : Qt.lighter(Theme.defaultBg, 1.2)

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 4
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: center.items.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "🔕"
                        font.pixelSize: 40
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifs.dnd ? "Do Not Disturb is on" : "No notifications"
                        color: Qt.darker(Theme.textColor, 1.5)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            // History list
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                visible: center.items.length > 0
                model: center.items

                delegate: Rectangle {
                    id: row
                    required property var modelData

                    readonly property bool critical:
                        modelData && modelData.urgency === NotificationUrgency.Critical

                    width: ListView.view.width
                    implicitHeight: rowLayout.implicitHeight + 20
                    radius: Theme.innerRadius
                    color: rowHover.containsMouse
                        ? Qt.lighter(Theme.defaultBg, 1.3)
                        : Qt.lighter(Theme.defaultBg, 1.15)
                    border.width: row.critical ? 1 : 0
                    border.color: Theme.urgentBg

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Column {
                        id: rowLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 4

                        Item {
                            width: parent.width
                            height: 18

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 14
                                    readonly property string iconSource: {
                                        const n = row.modelData
                                        if (!n || !n.appIcon) return ""
                                        return Quickshell.iconPath(n.appIcon, true)
                                    }
                                    visible: iconSource.length > 0
                                    source: iconSource
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData ? (row.modelData.appName || "Notification") : ""
                                    color: Qt.darker(Theme.textColor, 1.4)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 5
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                radius: 8
                                visible: rowHover.containsMouse || rowCloseHover.containsMouse
                                color: rowCloseHover.containsMouse ? Theme.urgentBg : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: Theme.textColor
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 7
                                }

                                MouseArea {
                                    id: rowCloseHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifs.dismiss(row.modelData)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: text.length > 0
                            text: row.modelData ? (row.modelData.summary || "") : ""
                            color: Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            font.bold: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: text.length > 0
                            text: row.modelData ? (row.modelData.body || "") : ""
                            color: Qt.darker(Theme.textColor, 1.2)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            textFormat: Text.StyledText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            onLinkActivated: (link) => Quickshell.execDetached(["xdg-open", link])
                        }
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }
        }
    }

    IpcHandler {
        target: "notifs"

        function toggle() {
            center.toggle(null)
        }

        function open() {
            center.show(null)
        }

        function close() {
            center.hide()
        }
    }
}
