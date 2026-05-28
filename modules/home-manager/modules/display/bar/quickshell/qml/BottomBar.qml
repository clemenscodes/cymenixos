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

        // ---------- LEFT ----------

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
            visible: ToplevelManager.toplevels.values.length > 0
            topMargin: 4
            bottomMargin: 4
            leftMargin: 8
            rightMargin: 8

            Row {
                spacing: 4

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
                            source: Quickshell.iconPath((tlButton.modelData.appId || "").toLowerCase(), "image-missing")
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

        // ---------- RIGHT ----------

        Pill {
            Layout.alignment: Qt.AlignVCenter
            visible: bar.currentSubmap !== "NORMAL"

            Text {
                text: bar.currentSubmap
                color: Theme.textColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        // System tray
        Pill {
            id: trayPill
            Layout.alignment: Qt.AlignVCenter
            visible: SystemTray.items.values.length > 0
            topMargin: 4
            bottomMargin: 4
            leftMargin: 8
            rightMargin: 8

            Row {
                spacing: 8

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

        // Volume (default sink)
        Pill {
            id: volPill
            Layout.alignment: Qt.AlignVCenter

            readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

            Item {
                implicitWidth: volText.implicitWidth
                implicitHeight: volText.implicitHeight

                Text {
                    id: volText
                    text: {
                        if (!volPill.audio) return "—"
                        if (volPill.audio.muted) return "🔇"
                        var v = Math.round(volPill.audio.volume * 100)
                        return `${v}% 🔊`
                    }
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            if (volPill.audio) {
                                volPill.audio.muted = !volPill.audio.muted
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            Quickshell.execDetached(["pavucontrol"])
                        }
                    }
                    onWheel: function(wheel) {
                        if (!volPill.audio) return
                        var step = 0.05
                        var newV = volPill.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)
                        volPill.audio.volume = Math.max(0, Math.min(1.5, newV))
                        wheel.accepted = true
                    }
                }
            }
        }

        // Mic (default source)
        Pill {
            id: micPill
            Layout.alignment: Qt.AlignVCenter

            readonly property var audio: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null

            Item {
                implicitWidth: micText.implicitWidth
                implicitHeight: micText.implicitHeight

                Text {
                    id: micText
                    text: {
                        if (!micPill.audio) return "—"
                        if (micPill.audio.muted) return "🚫 🎤"
                        var v = Math.round(micPill.audio.volume * 100)
                        return `${v}% 🎤`
                    }
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            if (micPill.audio) {
                                micPill.audio.muted = !micPill.audio.muted
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            Quickshell.execDetached(["pavucontrol"])
                        }
                    }
                    onWheel: function(wheel) {
                        if (!micPill.audio) return
                        var step = 0.01
                        var newV = micPill.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)
                        micPill.audio.volume = Math.max(0, Math.min(1.5, newV))
                        wheel.accepted = true
                    }
                }
            }
        }

        // Clock
        Pill {
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: clockText
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
        }
    }
}
