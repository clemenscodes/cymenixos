import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

PanelWindow {
    id: bar

    required property var screen
    required property var appLauncher
    required property var bluetoothMenu

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent"

    property string currentSubmap: "NORMAL"

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") {
                bar.currentSubmap = event.data.length > 0 ? event.data : "NORMAL"
            }
        }
    }

    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink,
            Pipewire.defaultAudioSource
        ]
    }

    IdleInhibitor {
        id: idleInhibit
        window: bar
        enabled: false
    }

    StyledTooltip {
        id: barTooltip
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.barMargin
        anchors.rightMargin: Theme.barMargin
        anchors.topMargin: 0
        anchors.bottomMargin: Theme.barMargin
        spacing: 4

        // -------- LEFT --------

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Theme.pillHeight
            implicitHeight: Theme.pillHeight
            color: "transparent"

            IconImage {
                anchors.fill: parent
                source: Quickshell.iconPath("nix-snowflake")
                implicitSize: parent.height
                smooth: true
                mipmap: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.appLauncher.toggle(bar)
            }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            visible: ToplevelManager.toplevels.values.length > 0
            contentPadding: 8

            Row {
                spacing: 4

                Repeater {
                    model: ToplevelManager.toplevels

                    delegate: Rectangle {
                        id: tlButton
                        required property Toplevel modelData

                        readonly property string resolvedIcon: {
                            const appId = (tlButton.modelData.appId || "").toLowerCase()
                            if (!appId) return ""
                            const entry = DesktopEntries.heuristicLookup(appId)
                            if (entry && entry.icon) return entry.icon
                            return appId
                        }

                        implicitWidth: 44
                        implicitHeight: Theme.pillHeight - 12
                        radius: Theme.innerRadius
                        color: tlHover.containsMouse
                            ? Qt.lighter(Theme.defaultBg, 1.4)
                            : Theme.defaultBg

                        Behavior on color {
                            ColorAnimation { duration: Theme.fadeMs / 2 }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 24
                            source: Quickshell.iconPath(tlButton.resolvedIcon, "application-x-executable")
                            smooth: true
                            mipmap: true
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tlButton.modelData.activated ? 22 : 0
                            height: 2
                            radius: 1
                            color: Theme.activeBg

                            Behavior on width {
                                NumberAnimation { duration: Theme.fadeMs }
                            }
                        }

                        MouseArea {
                            id: tlHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    tlButton.modelData.activate()
                                } else if (mouse.button === Qt.MiddleButton) {
                                    tlButton.modelData.fullscreen = !tlButton.modelData.fullscreen
                                } else if (mouse.button === Qt.RightButton) {
                                    tlButton.modelData.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // -------- RIGHT --------

        JsonPill {
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            command: ["qs-claude-monitor"]
            intervalMs: 60000
            onLeftClick: () => Quickshell.execDetached(["sh", "-c", "kitty -1 --title=kitty claude-monitor"])
        }

        JsonPill {
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            command: ["voxtype", "status", "--follow", "--format", "json"]
            streaming: true
            formatIcons: ({
                "idle": "🟢",
                "recording": "🔴",
                "transcribing": "🟡",
                "stopped": "⚪"
            })
            onLeftClick: () => Quickshell.execDetached(["systemctl", "--user", "restart", "voxtype"])
        }

        JsonPill {
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            command: ["wootswitch", "list", "--waybar"]
            intervalMs: 1000
            onLeftClick: () => Quickshell.execDetached(["wootswitch", "switch", "--next"])
            onRightClick: () => Quickshell.execDetached(["wootswitch", "switch", "--previous"])
        }

        Pill {
            id: submapPill
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: bar.currentSubmap === "NORMAL"
                ? "Current Hyprland submap: NORMAL (no submap active)"
                : `Current Hyprland submap: ${bar.currentSubmap}\nPress Mod+Shift+Escape to exit`

            Text {
                text: bar.currentSubmap
                color: bar.currentSubmap !== "NORMAL" ? Theme.warningColor : Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        JsonPill {
            id: notifPill
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            command: ["swaync-client", "-swb"]
            streaming: true
            formatIcons: ({
                "none": "🔔",
                "notification": "🔔",
                "dnd-none": "🔕",
                "dnd-notification": "🔕",
                "inhibited-none": "🔔",
                "inhibited-notification": "🔔",
                "dnd-inhibited-none": "🔕",
                "dnd-inhibited-notification": "🔕",
                "default": "🔔"
            })
            tooltipText: {
                const count = parseInt(notifPill.text) || 0
                const dnd = notifPill.iconName.startsWith("dnd-")
                let s
                if (count === 0) {
                    s = dnd ? "Do Not Disturb active" : "No new notifications"
                } else {
                    s = count + " unread notification" + (count === 1 ? "" : "s")
                    if (dnd) s += "  ·  DND active"
                }
                s += "\n\nLeft-click: toggle notification panel\nRight-click: toggle Do Not Disturb"
                return s
            }
            onLeftClick: () => Quickshell.execDetached(["swaync-client", "-t", "-sw"])
            onRightClick: () => Quickshell.execDetached(["swaync-client", "-d", "-sw"])
        }

        Pill {
            id: idlePill
            Layout.alignment: Qt.AlignVCenter
            interactive: true
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: idleInhibit.enabled
                ? "Idle inhibited — screen stays on. Click to allow sleep."
                : "Sleep allowed. Click to keep screen awake."
            onLeftClicked: idleInhibit.enabled = !idleInhibit.enabled

            Text {
                text: idleInhibit.enabled ? "☀️" : "🌙"
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 2
                font.bold: true
            }
        }

        Pill {
            id: btPill
            Layout.alignment: Qt.AlignVCenter
            interactive: true
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            visible: Bluetooth.defaultAdapter !== null

            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property int connectedCount: Bluetooth.devices
                ? Bluetooth.devices.values.filter(d => d.connected).length
                : 0
            readonly property bool poweredOn: adapter !== null && adapter.enabled

            // Nerd Font Awesome glyphs — written via fromCodePoint so the
            // file is pure ASCII and editor/git can't mangle the bytes.
            readonly property string btOnIcon: String.fromCodePoint(0xf293)
            readonly property string btOffIcon: String.fromCodePoint(0xf294)

            onLeftClicked: bar.bluetoothMenu.toggle(bar)
            onRightClicked: { if (adapter) adapter.enabled = !adapter.enabled }

            tooltipText: {
                if (!btPill.adapter) return "No Bluetooth adapter"
                if (!btPill.poweredOn) return "Bluetooth is off\nLeft-click: open menu\nRight-click: power on"
                if (btPill.connectedCount === 0) return "Bluetooth on, nothing connected\nLeft-click: open menu\nRight-click: power off"
                const names = Bluetooth.devices.values
                    .filter(d => d.connected)
                    .map(d => "• " + (d.deviceName || d.name || d.address))
                    .join("\n")
                return "Bluetooth on, " + btPill.connectedCount + " connected:\n" + names
                    + "\n\nLeft-click: open menu  ·  Right-click: power off"
            }

            Row {
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: btPill.poweredOn ? btPill.btOnIcon : btPill.btOffIcon
                    color: btPill.poweredOn
                        ? (btPill.connectedCount > 0 ? Theme.activeBg : Theme.textColor)
                        : Theme.mutedColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 8
                    font.bold: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: btPill.poweredOn && btPill.connectedCount > 0
                    text: btPill.connectedCount
                    color: Theme.activeBg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
            }
        }

        Pill {
            id: trayPill
            Layout.alignment: Qt.AlignVCenter
            visible: SystemTray.items.values.length > 0
            contentPadding: 10

            Row {
                spacing: 10

                Repeater {
                    model: SystemTray.items

                    delegate: Item {
                        id: trayDelegate
                        required property SystemTrayItem modelData

                        readonly property string tooltipText: {
                            const tt = trayDelegate.modelData.tooltipTitle
                                || trayDelegate.modelData.tooltipDescription
                                || ""
                            const title = trayDelegate.modelData.title || ""
                            const id = trayDelegate.modelData.id || ""
                            return tt || title || id
                        }

                        implicitWidth: 26
                        implicitHeight: 26

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 20
                            source: trayDelegate.modelData.icon
                            smooth: true
                            mipmap: true
                        }

                        MouseArea {
                            id: trayHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onEntered: barTooltip.showFor(trayDelegate, trayDelegate.tooltipText, bar)
                            onExited: barTooltip.hide()
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    if (trayDelegate.modelData.onlyMenu) {
                                        trayMenu.show(trayDelegate.modelData, trayDelegate, bar)
                                    } else {
                                        trayDelegate.modelData.activate()
                                    }
                                } else if (mouse.button === Qt.MiddleButton) {
                                    trayDelegate.modelData.secondaryActivate()
                                } else if (mouse.button === Qt.RightButton) {
                                    if (trayDelegate.modelData.hasMenu) {
                                        trayMenu.show(trayDelegate.modelData, trayDelegate, bar)
                                    }
                                }
                            }
                            onWheel: function(wheel) {
                                trayDelegate.modelData.scroll(wheel.angleDelta.y, false)
                                wheel.accepted = true
                            }
                        }
                    }
                }
            }
        }

        TrayMenu {
            id: trayMenu
        }

        Pill {
            id: volPill
            Layout.alignment: Qt.AlignVCenter
            interactive: true
            tooltipHost: barTooltip
            tooltipHostWindow: bar

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property var audio: sink ? sink.audio : null
            readonly property string sinkName: sink
                ? (sink.nickname || sink.description || sink.name || "Audio output")
                : "Audio output"

            tooltipText: {
                let s = "Output: " + volPill.sinkName
                if (volPill.audio) {
                    s += "\nVolume: " + Math.round(volPill.audio.volume * 100) + "%"
                        + (volPill.audio.muted ? "  (muted)" : "")
                }
                s += "\n\nScroll: adjust  ·  Click: mute  ·  Right-click: pavucontrol"
                return s
            }

            onLeftClicked: { if (volPill.audio) volPill.audio.muted = !volPill.audio.muted }
            onRightClicked: Quickshell.execDetached(["pavucontrol"])
            onScrolledUp: {
                if (!volPill.audio) return
                volPill.audio.volume = Math.max(0, Math.min(1.5, volPill.audio.volume + 0.05))
            }
            onScrolledDown: {
                if (!volPill.audio) return
                volPill.audio.volume = Math.max(0, Math.min(1.5, volPill.audio.volume - 0.05))
            }

            Text {
                text: {
                    if (!volPill.audio) return "—"
                    if (volPill.audio.muted) return "🔇"
                    const v = Math.round(volPill.audio.volume * 100)
                    return `${v}% 🔊`
                }
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        Pill {
            id: micPill
            Layout.alignment: Qt.AlignVCenter
            interactive: true
            tooltipHost: barTooltip
            tooltipHostWindow: bar

            readonly property var src: Pipewire.defaultAudioSource
            readonly property var audio: src ? src.audio : null
            readonly property string srcName: src
                ? (src.nickname || src.description || src.name || "Audio input")
                : "Audio input"

            tooltipText: {
                let s = "Input: " + micPill.srcName
                if (micPill.audio) {
                    s += "\nVolume: " + Math.round(micPill.audio.volume * 100) + "%"
                        + (micPill.audio.muted ? "  (muted)" : "")
                }
                s += "\n\nScroll: adjust  ·  Click: mute  ·  Right-click: pavucontrol"
                return s
            }

            onLeftClicked: { if (micPill.audio) micPill.audio.muted = !micPill.audio.muted }
            onRightClicked: Quickshell.execDetached(["pavucontrol"])
            onScrolledUp: {
                if (!micPill.audio) return
                micPill.audio.volume = Math.max(0, Math.min(1.5, micPill.audio.volume + 0.01))
            }
            onScrolledDown: {
                if (!micPill.audio) return
                micPill.audio.volume = Math.max(0, Math.min(1.5, micPill.audio.volume - 0.01))
            }

            Text {
                text: {
                    if (!micPill.audio) return "—"
                    if (micPill.audio.muted) return "🚫 🎤"
                    const v = Math.round(micPill.audio.volume * 100)
                    return `${v}% 🎤`
                }
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        Pill {
            id: clockPill
            Layout.alignment: Qt.AlignVCenter
            tooltipHost: barTooltip
            tooltipHostWindow: bar
            tooltipText: Qt.formatDateTime(clock.now, "dddd, dd MMMM yyyy")

            QtObject {
                id: clock
                property date now: new Date()
            }

            Timer {
                interval: 5000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: clock.now = new Date()
            }

            Text {
                text: Qt.formatDateTime(clock.now, "HH:mm") + " 🕐"
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }
    }
}
