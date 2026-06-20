import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

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

                        // Lights up when a window on this (unfocused) workspace
                        // raises the attention/urgent hint — e.g. a browser
                        // download finishing or a chat ping. Cleared on focus.
                        property bool urgent: {
                            if (wsButton.modelData.focused) return false
                            const tls = Hyprland.toplevels ? Hyprland.toplevels.values : []
                            for (let i = 0; i < tls.length; ++i) {
                                const ws = tls[i].workspace
                                if (ws && ws.id === wsButton.modelData.id && tls[i].urgent)
                                    return true
                            }
                            return false
                        }

                        implicitWidth: 44
                        implicitHeight: Theme.pillHeight - 12
                        radius: Theme.innerRadius
                        color: wsButton.urgent
                            ? Theme.urgentBg
                            : (hoverArea.containsMouse
                                ? Qt.lighter(Theme.defaultBg, 1.4)
                                : Theme.defaultBg)

                        Behavior on color {
                            ColorAnimation { duration: Theme.fadeMs / 2 }
                        }

                        Text {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: `${wsButton.modelData.id}`
                            color: wsButton.modelData.focused ? Theme.activeBg : Theme.textColor
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: wsButton.modelData.focused
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
            id: batteryPill
            Layout.alignment: Qt.AlignVCenter
            interactive: true
            tooltipHost: barTooltip
            tooltipHostWindow: bar

            // UPower.displayDevice is the aggregate battery; on desktops it is
            // not a laptop battery / not present, so the pill hides itself —
            // matching the waybar `mkIf isLaptop "battery"` gating.
            readonly property var dev: UPower.displayDevice
            visible: dev && dev.isLaptopBattery && dev.isPresent

            // Quickshell reports percentage as 0..1; scale to 0..100.
            readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
            readonly property int st: dev ? dev.state : UPowerDeviceState.Unknown
            readonly property bool charging: st === UPowerDeviceState.Charging
                || st === UPowerDeviceState.PendingCharge
            readonly property bool plugged: st === UPowerDeviceState.FullyCharged
                || st === UPowerDeviceState.PendingDischarge

            // format-alt: tap to toggle remaining-time display, like waybar.
            property bool showTime: false
            onLeftClicked: showTime = !showTime

            function _fmtDuration(secs) {
                if (!secs || secs <= 0) return ""
                const h = Math.floor(secs / 3600)
                const m = Math.floor((secs % 3600) / 60)
                return h > 0 ? (h + "h " + m + "m") : (m + "m")
            }

            // waybar states: good=60, warning=30, critical=15 -> 💀/🪫/🔋
            readonly property string levelIcon: {
                if (charging) return "⚡"
                if (plugged) return "🔌"
                if (pct <= 15) return "💀"
                if (pct <= 30) return "🪫"
                return "🔋"
            }

            readonly property string timeText: charging
                ? _fmtDuration(dev ? dev.timeToFull : 0)
                : _fmtDuration(dev ? dev.timeToEmpty : 0)

            tooltipText: {
                if (!batteryPill.dev) return "No battery"
                let s = "Battery " + batteryPill.pct + "%"
                if (batteryPill.charging) {
                    s += " — charging"
                    if (batteryPill.timeText) s += "\nTime to full: " + batteryPill.timeText
                } else if (batteryPill.plugged) {
                    s += " — plugged in"
                } else {
                    s += " — on battery"
                    if (batteryPill.timeText) s += "\nTime to empty: " + batteryPill.timeText
                }
                if (batteryPill.dev.healthSupported && batteryPill.dev.healthPercentage > 0)
                    s += "\nHealth: " + Math.round(batteryPill.dev.healthPercentage) + "%"
                s += "\n\nClick: toggle remaining time"
                return s
            }

            Text {
                text: (batteryPill.showTime && batteryPill.timeText
                        ? batteryPill.timeText
                        : batteryPill.pct + "%")
                    + " " + batteryPill.levelIcon
                color: {
                    if (batteryPill.charging || batteryPill.plugged) return Theme.textColor
                    if (batteryPill.pct <= 15) return Theme.criticalColor
                    if (batteryPill.pct <= 30) return Theme.warningColor
                    return Theme.textColor
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
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
