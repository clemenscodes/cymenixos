import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

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

            // Reads /sys/class/power_supply/BAT0 directly (like Brightness reads
            // brightnessctl) — no upower daemon needed. On desktops BAT0 does not
            // exist, the poll yields nothing, and the pill stays hidden. This is
            // the runtime equivalent of waybar's `mkIf isLaptop "battery"`.
            property bool available: false
            property int pct: 0
            property string status: ""
            // energy_now/energy_full in µWh and power_now in µW (or the charge_*/
            // current_* equivalents); the now/rate ratio gives hours either way.
            property real energyNow: 0
            property real energyFull: 0
            property real powerNow: 0

            visible: available

            readonly property bool charging: status === "Charging"
            readonly property bool plugged: status === "Full" || status === "Not charging"

            // format-alt: tap to toggle remaining-time display, like waybar.
            property bool showTime: false
            onLeftClicked: showTime = !showTime

            // Hours until empty (discharging) or full (charging), 0 if unknown.
            readonly property real hoursRemaining: {
                if (powerNow <= 0) return 0
                if (charging) return (energyFull - energyNow) / powerNow
                if (status === "Discharging") return energyNow / powerNow
                return 0
            }

            function _fmtHours(h) {
                if (!h || h <= 0) return ""
                const total = Math.round(h * 60)
                const hh = Math.floor(total / 60)
                const mm = total % 60
                return hh > 0 ? (hh + "h " + mm + "m") : (mm + "m")
            }

            readonly property string timeText: _fmtHours(hoursRemaining)

            // waybar states: good=60, warning=30, critical=15 -> 💀/🪫/🔋
            readonly property string levelIcon: {
                if (charging) return "⚡"
                if (plugged) return "🔌"
                if (pct <= 15) return "💀"
                if (pct <= 30) return "🪫"
                return "🔋"
            }

            tooltipText: {
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
                s += "\n\nClick: toggle remaining time"
                return s
            }

            Timer {
                interval: 10000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: batProc.running = true
            }

            Process {
                id: batProc
                command: ["sh", "-c",
                    "b=/sys/class/power_supply/BAT0; [ -d \"$b\" ] || exit 0; " +
                    "cat \"$b/capacity\"; cat \"$b/status\"; " +
                    "cat \"$b/energy_now\" 2>/dev/null || cat \"$b/charge_now\" 2>/dev/null || echo 0; " +
                    "cat \"$b/energy_full\" 2>/dev/null || cat \"$b/charge_full\" 2>/dev/null || echo 0; " +
                    "cat \"$b/power_now\" 2>/dev/null || cat \"$b/current_now\" 2>/dev/null || echo 0"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = this.text.split("\n").map(l => l.trim()).filter(l => l.length > 0)
                        if (lines.length < 5) { batteryPill.available = false; return }
                        const c = parseInt(lines[0])
                        if (isNaN(c)) { batteryPill.available = false; return }
                        batteryPill.pct = c
                        batteryPill.status = lines[1]
                        batteryPill.energyNow = parseFloat(lines[2]) || 0
                        batteryPill.energyFull = parseFloat(lines[3]) || 0
                        batteryPill.powerNow = parseFloat(lines[4]) || 0
                        batteryPill.available = true
                    }
                }
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
