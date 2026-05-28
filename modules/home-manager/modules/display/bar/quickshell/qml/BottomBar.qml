import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

PanelWindow {
    id: bar

    required property var screen

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

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.barMargin
        anchors.rightMargin: Theme.barMargin
        anchors.topMargin: 0
        anchors.bottomMargin: Theme.barMargin
        spacing: 4

        // ---------- LEFT: logo + taskbar ----------

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Theme.barHeight - 12
            implicitHeight: Theme.barHeight - 12
            color: "transparent"

            IconImage {
                anchors.fill: parent
                source: Quickshell.iconPath("nix-snowflake")
                implicitSize: parent.height
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["sh", "-c", "sleep 0.3; rofi -show drun"])
            }
        }

        Pill {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            visible: ToplevelManager.toplevels.values.length > 0
            verticalPadding: 4
            horizontalPadding: 8

            content: [
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: ToplevelManager.toplevels

                        delegate: Rectangle {
                            id: tlButton
                            required property Toplevel modelData

                            implicitWidth: 36
                            implicitHeight: 28
                            radius: Theme.innerRadius
                            color: modelData.activated
                                ? Theme.activeBg
                                : (tlHover.containsMouse ? Qt.rgba(0.85, 0.76, 0.77, 0.3) : "transparent")

                            Behavior on color {
                                ColorAnimation { duration: Theme.fadeMs }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 22
                                source: {
                                    var appId = tlButton.modelData.appId || ""
                                    var p = Quickshell.iconPath(appId.toLowerCase(), true)
                                    if (p) return p
                                    return Quickshell.iconPath("application-x-executable")
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
            ]
        }

        Item { Layout.fillWidth: true }

        // ---------- RIGHT: submap + tray + audio + clock ----------

        Pill {
            Layout.alignment: Qt.AlignVCenter
            visible: bar.currentSubmap !== "NORMAL"

            content: [
                Text {
                    anchors.centerIn: parent
                    text: bar.currentSubmap
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
            ]
        }

        // System tray
        Pill {
            id: trayPill
            Layout.alignment: Qt.AlignVCenter
            visible: SystemTray.items.values.length > 0
            verticalPadding: 4
            horizontalPadding: 8

            content: [
                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            id: trayDelegate
                            required property SystemTrayItem modelData

                            implicitWidth: 28
                            implicitHeight: 28

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 22
                                source: trayDelegate.modelData.icon
                            }

                            MouseArea {
                                id: trayArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (trayDelegate.modelData.onlyMenu) {
                                            trayMenu.menu = trayDelegate.modelData.menu
                                            trayMenu.open()
                                        } else {
                                            trayDelegate.modelData.activate()
                                        }
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        trayDelegate.modelData.secondaryActivate()
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (trayDelegate.modelData.hasMenu) {
                                            trayMenu.menu = trayDelegate.modelData.menu
                                            trayMenu.open()
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
            ]
        }

        QsMenuAnchor {
            id: trayMenu
            anchor {
                window: bar
                rect.x: trayPill.x + trayPill.width / 2
                rect.y: 0
                rect.height: 1
                rect.width: 1
                edges: Edges.Top
                gravity: Edges.Top
            }
        }

        // Pulseaudio sink (volume)
        Pill {
            Layout.alignment: Qt.AlignVCenter
            verticalPadding: 4

            property var sinkNode: Pipewire.defaultAudioSink
            property var audio: sinkNode ? sinkNode.audio : null

            content: [
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!parent.parent.audio) return "—"
                        if (parent.parent.audio.muted) return "🔇"
                        var v = Math.round(parent.parent.audio.volume * 100)
                        return `${v}% 🔊`
                    }
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                },
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            if (parent.parent.audio) {
                                parent.parent.audio.muted = !parent.parent.audio.muted
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            Quickshell.execDetached(["pavucontrol"])
                        }
                    }
                    onWheel: function(wheel) {
                        if (!parent.parent.audio) return
                        var step = 0.05
                        var newV = parent.parent.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)
                        parent.parent.audio.volume = Math.max(0, Math.min(1.5, newV))
                        wheel.accepted = true
                    }
                }
            ]
        }

        // Mic (source)
        Pill {
            Layout.alignment: Qt.AlignVCenter
            verticalPadding: 4

            property var srcNode: Pipewire.defaultAudioSource
            property var audio: srcNode ? srcNode.audio : null

            content: [
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!parent.parent.audio) return "—"
                        if (parent.parent.audio.muted) return "🚫 🎤"
                        var v = Math.round(parent.parent.audio.volume * 100)
                        return `${v}% 🎤`
                    }
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                },
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            if (parent.parent.audio) {
                                parent.parent.audio.muted = !parent.parent.audio.muted
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            Quickshell.execDetached(["pavucontrol"])
                        }
                    }
                    onWheel: function(wheel) {
                        if (!parent.parent.audio) return
                        var step = 0.01
                        var newV = parent.parent.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)
                        parent.parent.audio.volume = Math.max(0, Math.min(1.5, newV))
                        wheel.accepted = true
                    }
                }
            ]
        }

        // Clock
        Pill {
            Layout.alignment: Qt.AlignVCenter
            verticalPadding: 4

            content: [
                Text {
                    id: clockText
                    anchors.centerIn: parent
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    text: Qt.formatDateTime(clock.now, "ddd dd.MM.yyyy HH:mm:ss")

                    QtObject {
                        id: clock
                        property date now: new Date()
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: clock.now = new Date()
                    }
                }
            ]
        }
    }
}
