import QtQuick
import QtQuick.Controls
import Quickshell

// Popover for NightLight: warm toggle, temperature, brightness and display off.
// Same look and hide behaviour as SliderPopup.
PopupWindow {
    id: popup

    property Item targetItem: null
    property var targetWindow: null
    property string placement: "above"
    property int verticalGap: 8

    color: "transparent"
    visible: false

    implicitWidth: 320
    implicitHeight: 218

    anchor {
        window: popup.targetWindow
        rect.x: popup.targetItem
            ? popup.targetItem.mapToItem(null, 0, 0).x + popup.targetItem.width / 2 - popup.implicitWidth / 2
            : 0
        rect.y: popup.placement === "above"
            ? -popup.verticalGap
            : (popup.targetWindow ? popup.targetWindow.height + popup.verticalGap : popup.verticalGap)
        rect.width: 1
        rect.height: 1
        edges: popup.placement === "above" ? Edges.Top : Edges.Bottom
        gravity: popup.placement === "above" ? Edges.Top : Edges.Bottom
    }

    property bool hovered: false
    readonly property bool dragging: tempSlider.pressed || brightSlider.pressed

    function toggleFor(item, window) {
        if (popup.visible) { popup.hide(); return }
        popup.show(item, window)
    }

    function show(item, window) {
        popup.targetItem = item
        popup.targetWindow = window
        popup.visible = true
        hideTimer.restart()
    }

    function hide() { popup.visible = false }

    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: { if (!popup.hovered && !popup.dragging) popup.hide() }
    }

    onDraggingChanged: { if (!dragging && !hovered) hideTimer.restart() }

    component Row3: Item {
        property alias label: labelText.text
        property alias value: valueText.text
        property alias labelColor: labelText.color
        width: parent.width
        height: 20

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.bold: true
        }

        Text {
            id: valueText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.activeBg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            font.bold: true
        }
    }

    component StyledSlider: Slider {
        id: s
        property bool dimmed: false
        width: parent.width
        height: 20

        background: Rectangle {
            x: s.leftPadding
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: s.availableWidth
            height: 8
            radius: 4
            color: Qt.darker(Theme.defaultBg, 1.7)

            Rectangle {
                width: s.visualPosition * parent.width
                height: parent.height
                radius: 4
                color: s.dimmed ? Theme.mutedColor : Theme.activeBg
            }
        }

        handle: Rectangle {
            x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
            y: s.topPadding + s.availableHeight / 2 - height / 2
            width: 18
            height: 18
            radius: 9
            color: s.pressed ? Qt.lighter(Theme.activeBg, 1.15) : Theme.textColor
            border.color: Theme.activeBg
            border.width: 2
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        HoverHandler {
            id: hover
            onHoveredChanged: {
                popup.hovered = hover.hovered
                if (hover.hovered) hideTimer.stop()
                else hideTimer.restart()
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // ----- warm toggle + temperature -----
            Row3 {
                label: "🌅  Warm light " + (NightLight.warm ? "on" : "off")
                labelColor: NightLight.warm ? Theme.textColor : Theme.mutedColor
                value: NightLight.temperature + " K"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NightLight.toggleWarm()
                }
            }

            StyledSlider {
                id: tempSlider
                from: NightLight.minTemperature
                to: NightLight.maxTemperature
                stepSize: 50
                dimmed: !NightLight.warm
                Binding on value {
                    value: NightLight.temperature
                    when: !tempSlider.pressed
                }
                onMoved: {
                    NightLight.setTemperature(tempSlider.value)
                    if (!NightLight.warm) NightLight.setWarm(true)
                }
            }

            // ----- brightness -----
            Row3 {
                label: "🔆  Brightness"
                value: NightLight.brightness + "%"
            }

            StyledSlider {
                id: brightSlider
                from: NightLight.minBrightness
                to: 100
                stepSize: 1
                Binding on value {
                    value: NightLight.brightness
                    when: !brightSlider.pressed
                }
                onMoved: NightLight.setBrightness(brightSlider.value)
            }

            // ----- reset / display off -----
            Row {
                width: parent.width
                spacing: 8

            Rectangle {
                width: (parent.width - 8) * 0.35
                height: 30
                radius: Theme.innerRadius
                color: resetHover.containsMouse ? Qt.lighter(Theme.defaultBg, 1.4) : Qt.darker(Theme.defaultBg, 1.3)

                Text {
                    anchors.centerIn: parent
                    text: "↺  Reset"
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                }

                MouseArea {
                    id: resetHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NightLight.reset()
                }
            }

            Rectangle {
                width: (parent.width - 8) * 0.65
                height: 30
                radius: Theme.innerRadius
                color: offHover.containsMouse ? Qt.lighter(Theme.defaultBg, 1.4) : Qt.darker(Theme.defaultBg, 1.3)

                Text {
                    anchors.centerIn: parent
                    text: "⏻  Display off"
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                }

                MouseArea {
                    id: offHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { popup.hide(); NightLight.displayOff() }
                }
            }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Super+Alt+Backspace resets  ·  any key wakes the display"
                color: Theme.mutedColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 5
            }
        }
    }
}
