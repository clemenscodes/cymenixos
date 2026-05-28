import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: menu

    readonly property int cardWidth: 360
    readonly property int cardHeight: 360

    readonly property var actions: [
        { icon: "🔒", label: "Lock",      cmd: ["loginctl", "lock-session"] },
        { icon: "🚪", label: "Log out",   cmd: ["sh", "-c", "loginctl kill-user $USER"] },
        { icon: "💤", label: "Suspend",   cmd: ["sh", "-c", "loginctl lock-session && sleep 1 && systemctl suspend"] },
        { icon: "❄",  label: "Hibernate", cmd: ["sh", "-c", "loginctl lock-session && sleep 1 && systemctl hibernate"] },
        { icon: "🔄", label: "Reboot",    cmd: ["systemctl", "reboot"] },
        { icon: "⏻",  label: "Shut down", cmd: ["systemctl", "poweroff"] }
    ]

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
        menu.visible = true
        Qt.callLater(() => menu.forceActiveFocus())
    }

    function hide() {
        menu.visible = false
    }

    function runAction(cmd) {
        Quickshell.execDetached(cmd)
        menu.hide()
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            menu.hide()
            event.accepted = true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: menu.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: menu.cardWidth
        height: menu.cardHeight
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: { /* swallow */ }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Power"
                color: Theme.activeBg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Repeater {
                model: menu.actions

                delegate: Rectangle {
                    id: btn
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
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
                        anchors.leftMargin: 16
                        spacing: 16

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: btn.modelData.icon
                            color: Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 6
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

    IpcHandler {
        target: "powermenu"

        function toggle() {
            menu.toggle(null)
        }

        function open() {
            menu.show(null)
        }

        function close() {
            menu.hide()
        }
    }
}
