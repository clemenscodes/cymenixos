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
            contentPadding: 6

            Row {
                spacing: Theme.pillSpacing

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        id: wsButton
                        required property HyprlandWorkspace modelData

                        implicitWidth: wsLabel.implicitWidth + 16
                        implicitHeight: 26
                        radius: Theme.innerRadius
                        color: modelData.focused
                            ? Theme.activeBg
                            : (hoverArea.containsMouse ? Qt.rgba(0.85, 0.76, 0.77, 0.3) : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: Theme.fadeMs }
                        }

                        Text {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: `-> ${wsButton.modelData.id}`
                            color: wsButton.modelData.focused ? Theme.activeTextColor : Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
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
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            command: ["waybar-mail"]
            intervalMs: 5000
            onLeftClick: () => Quickshell.execDetached(["thunderbird"])
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
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
            color: Theme.powerBg
            interactive: true
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
