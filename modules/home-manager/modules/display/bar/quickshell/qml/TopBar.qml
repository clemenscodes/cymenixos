import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: bar

    required property var screen
    required property var powerMenu

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
                spacing: 4

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        id: wsButton
                        required property HyprlandWorkspace modelData

                        // "Lit up" when the workspace holds at least one window
                        // (e.g. a browser). Derived from live toplevels so it
                        // updates the moment a window opens, closes or moves.
                        property bool occupied: {
                            const tls = Hyprland.toplevels ? Hyprland.toplevels.values : []
                            for (let i = 0; i < tls.length; ++i) {
                                const ws = tls[i].workspace
                                if (ws && ws.id === wsButton.modelData.id)
                                    return true
                            }
                            return false
                        }

                        implicitWidth: 44
                        implicitHeight: Theme.pillHeight - 12
                        radius: Theme.innerRadius
                        color: hoverArea.containsMouse
                            ? Qt.lighter(Theme.defaultBg, 1.4)
                            : Theme.defaultBg

                        Behavior on color {
                            ColorAnimation { duration: Theme.fadeMs / 2 }
                        }

                        Text {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: `${wsButton.modelData.id}`
                            color: wsButton.modelData.focused
                                ? Theme.activeBg
                                : (wsButton.occupied ? Theme.textColor : Theme.mutedColor)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: wsButton.modelData.focused
                        }

                        // occupied indicator — fades in when the workspace
                        // gains a window, fades out when it empties
                        Rectangle {
                            anchors.top: parent.top
                            anchors.topMargin: 5
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.activeBg
                            opacity: (wsButton.occupied && !wsButton.modelData.focused) ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Theme.fadeMs }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: wsButton.modelData.focused ? 22 : 0
                            height: 2
                            radius: 1
                            color: Theme.activeBg

                            Behavior on width {
                                NumberAnimation { duration: Theme.fadeMs }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
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
            command: ["qs-mail"]
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
            command: ["qs-nvidia"]
            intervalMs: 5000
            onLeftClick: () => Quickshell.execDetached(["sh", "-c", "kitty -1 --title=kitty nvtop"])
        }

        Pill {
            id: powerPill
            Layout.alignment: Qt.AlignVCenter
            baseColor: Theme.powerBg
            interactive: true
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: "Power menu (SUPER+Backspace)\nLeft-click: open lock / suspend / reboot / shutdown / logout"
            onLeftClicked: bar.powerMenu.toggle(bar)

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
