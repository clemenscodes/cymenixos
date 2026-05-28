import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: bar

    required property var screen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent"

    StyledTooltip {
        id: barTooltip
        placement: "below"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.barMargin
        anchors.rightMargin: Theme.barMargin
        anchors.topMargin: Theme.barMargin
        anchors.bottomMargin: 0
        spacing: 4

        // -------- LEFT: workspaces --------

        Pill {
            Layout.alignment: Qt.AlignVCenter
            contentPadding: 10

            Row {
                spacing: 14

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Item {
                        id: wsButton
                        required property HyprlandWorkspace modelData

                        implicitWidth: wsLabel.implicitWidth
                        implicitHeight: Theme.pillHeight - 14

                        Text {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: `${wsButton.modelData.id}`
                            color: wsButton.modelData.focused
                                ? Theme.warningColor
                                : (hoverArea.containsMouse ? Theme.activeBg : Theme.textColor)
                            opacity: wsButton.modelData.focused ? 1.0 : 0.7
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: wsButton.modelData.focused

                            Behavior on color {
                                ColorAnimation { duration: Theme.fadeMs / 2 }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: wsButton.modelData.focused ? wsLabel.implicitWidth : 0
                            height: 2
                            radius: 1
                            color: Theme.warningColor

                            Behavior on width {
                                NumberAnimation { duration: Theme.fadeMs }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            anchors.margins: -4
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wsButton.modelData.activate()
                            onWheel: function(wheel) {
                                if (wheel.angleDelta.y > 0) {
                                    Hyprland.dispatch(`hl.dsp.focus({ workspace = "e+1" })`)
                                } else if (wheel.angleDelta.y < 0) {
                                    Hyprland.dispatch(`hl.dsp.focus({ workspace = "e-1" })`)
                                }
                                wheel.accepted = true
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // -------- RIGHT: stats + custom modules + powermenu --------

        JsonPill {
            id: mailPill
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            command: ["waybar-mail"]
            intervalMs: 5000
            tooltipText: {
                const m = mailPill.text.match(/(\d+)/)
                const count = m ? parseInt(m[1]) : 0
                let s
                if (count === 0) {
                    s = "Inbox is clean — no unread mail"
                } else {
                    s = count + " unread message" + (count === 1 ? "" : "s") + " in INBOX"
                }
                s += "\n\nLeft-click: open Thunderbird"
                return s
            }
            onLeftClick: () => Quickshell.execDetached(["thunderbird"])
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: SysStats.diskTooltip
            Text {
                text: `${SysStats.diskUsage || "—"} 💾`
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: SysStats.memTooltip
            Text {
                text: `${SysStats.memPercent}% 🧠`
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            visible: SysStats.tempC > 0
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: SysStats.tempTooltip
            Text {
                text: `${SysStats.tempC}°C 🌡️`
                color: SysStats.tempC >= 80 ? Theme.criticalColor : Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: SysStats.cpuTooltip
            Text {
                text: `${SysStats.cpuPercent}% ⚙️`
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        JsonPill {
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            command: ["waybar-nvidia"]
            intervalMs: 5000
            onLeftClick: () => Quickshell.execDetached(["sh", "-c", "kitty -1 --title=kitty nvtop"])
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            baseColor: Theme.powerBg
            interactive: true
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: "Power menu\nLeft-click: open shutdown / reboot / lock / logout menu"
            onLeftClicked: Quickshell.execDetached(["sh", "-c", "sleep 0.1 && logoutlaunch"])

            Text {
                text: "⏻"
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 4
                font.bold: true
            }
        }
    }
}
