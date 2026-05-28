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

    implicitHeight: 60
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 12
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                color: "#4A3C63"
                radius: 12
                implicitHeight: 36
                implicitWidth: workspacesRow.implicitWidth + 16

                Row {
                    id: workspacesRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: Hyprland.workspaces

                        delegate: Rectangle {
                            id: wsButton
                            required property HyprlandWorkspace modelData

                            width: 56
                            height: 28
                            radius: 8
                            color: modelData.focused ? "#D8C1C4" : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: `-> ${wsButton.modelData.id}`
                                color: wsButton.modelData.focused ? "#58505E" : "#ffffff"
                                font.family: "Iosevka Nerd Font Mono"
                                font.pixelSize: 16
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
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

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                color: "#4A3C63"
                radius: 12
                implicitHeight: 36
                implicitWidth: clockText.implicitWidth + 24

                Text {
                    id: clockText
                    anchors.centerIn: parent
                    color: "#ffffff"
                    font.family: "Iosevka Nerd Font Mono"
                    font.pixelSize: 16
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
}
