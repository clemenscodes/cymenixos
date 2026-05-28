import QtQuick
import Quickshell

PopupWindow {
    id: menu

    property Item anchorItem: null
    property var anchorWindow: null

    readonly property var actions: [
        { icon: "🔒", label: "Lock",      tip: "Lock the session",            cmd: ["loginctl", "lock-session"] },
        { icon: "🚪", label: "Log out",   tip: "End the user session",        cmd: ["sh", "-c", "loginctl kill-user $USER"] },
        { icon: "💤", label: "Suspend",   tip: "Suspend to RAM",              cmd: ["sh", "-c", "loginctl lock-session && sleep 1 && systemctl suspend"] },
        { icon: "❄",  label: "Hibernate", tip: "Suspend to disk",             cmd: ["sh", "-c", "loginctl lock-session && sleep 1 && systemctl hibernate"] },
        { icon: "🔄", label: "Reboot",    tip: "Restart the machine",         cmd: ["systemctl", "reboot"] },
        { icon: "⏻",  label: "Shut down", tip: "Power off the machine",       cmd: ["systemctl", "poweroff"] }
    ]

    color: "transparent"
    visible: false
    grabFocus: true

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    anchor {
        window: menu.anchorWindow
        rect.x: menu.anchorItem
            ? menu.anchorItem.mapToItem(null, 0, 0).x + menu.anchorItem.width / 2 - menu.implicitWidth / 2
            : 0
        rect.y: menu.anchorWindow ? menu.anchorWindow.height + 6 : 6
        rect.width: 1
        rect.height: 1
        edges: Edges.Bottom
        gravity: Edges.Bottom
    }

    function show(item, window) {
        menu.anchorItem = item
        menu.anchorWindow = window
        menu.visible = true
    }

    function hide() {
        menu.visible = false
    }

    function runAction(cmd) {
        Quickshell.execDetached(cmd)
        menu.hide()
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        implicitWidth: 260
        implicitHeight: header.implicitHeight + actionsColumn.implicitHeight + 24

        Text {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            text: "Power menu"
            color: Theme.activeBg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Column {
            id: actionsColumn
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            anchors.topMargin: 6
            spacing: 4

            Repeater {
                model: menu.actions

                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    width: actionsColumn.width
                    height: 40
                    radius: Theme.innerRadius
                    color: btnMouse.containsMouse
                        ? Qt.lighter(Theme.defaultBg, 1.4)
                        : Theme.defaultBg

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 14
                        spacing: 14

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: btn.modelData.icon
                            color: Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 4
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: btn.modelData.label
                            color: Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: btnMouse.containsMouse
                        }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menu.runAction(btn.modelData.cmd)
                    }
                }
            }
        }
    }
}
