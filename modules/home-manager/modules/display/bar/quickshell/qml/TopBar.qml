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

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.barMargin
        anchors.rightMargin: Theme.barMargin
        anchors.topMargin: Theme.barMargin
        anchors.bottomMargin: 0
        spacing: 4

        Pill {
            Layout.alignment: Qt.AlignVCenter
            topMargin: 4
            bottomMargin: 4
            leftMargin: 8
            rightMargin: 8

            Row {
                spacing: Theme.pillSpacing

                Repeater {
                    model: Hyprland.workspaces

                    delegate: Rectangle {
                        id: wsButton
                        required property HyprlandWorkspace modelData

                        implicitWidth: wsLabel.implicitWidth + 24
                        implicitHeight: wsLabel.implicitHeight + 12
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
    }
}
