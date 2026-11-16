import QtQuick
import QtQuick.Controls
import Quickshell

// Popover for the Elgato Key Lights: power, colour temperature and brightness per light.
// Same look and hide behaviour as NightLightPopup.
PopupWindow {
    id: popup

    property Item targetItem: null
    property var targetWindow: null
    property string placement: "above"
    property int verticalGap: 8

    color: "transparent"
    visible: false

    implicitWidth: 320
    implicitHeight: content.implicitHeight + 28

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
    // The sliders live in a Repeater, so each one counts itself in while pressed.
    property int pressedSliders: 0
    readonly property bool dragging: pressedSliders > 0

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
        onPressedChanged: popup.pressedSliders += s.pressed ? 1 : -1

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
            id: content
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            // The model is the list of names, which only changes when the lights do, so a
            // state update never rebuilds a block (and never drops a slider mid-drag).
            Repeater {
                model: Keylight.names

                delegate: Column {
                    id: block
                    required property string modelData
                    readonly property var light: Keylight.light(block.modelData)
                    readonly property string title:
                        block.modelData.charAt(0).toUpperCase() + block.modelData.slice(1)

                    width: content.width
                    spacing: 8

                    // ----- power + temperature -----
                    Row3 {
                        label: "💡  " + block.title + " "
                            + (!block.light.available ? "unreachable" : block.light.on ? "on" : "off")
                        labelColor: block.light.available && block.light.on ? Theme.textColor : Theme.mutedColor
                        value: block.light.available ? block.light.temperature + " K" : ""

                        MouseArea {
                            anchors.fill: parent
                            enabled: block.light.available
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Keylight.toggleLight(block.modelData)
                        }
                    }

                    StyledSlider {
                        id: tempSlider
                        visible: block.light.available
                        from: Keylight.minTemperature
                        to: Keylight.maxTemperature
                        stepSize: 50
                        dimmed: !block.light.on
                        Binding on value {
                            value: block.light.temperature || Keylight.minTemperature
                            when: !tempSlider.pressed
                        }
                        onMoved: Keylight.setTemperature(block.modelData, tempSlider.value)
                    }

                    // ----- brightness -----
                    Row3 {
                        visible: block.light.available
                        label: "🔆  Brightness"
                        value: block.light.brightness + "%"
                    }

                    StyledSlider {
                        id: brightSlider
                        visible: block.light.available
                        from: Keylight.minBrightness
                        to: 100
                        stepSize: 1
                        dimmed: !block.light.on
                        Binding on value {
                            value: block.light.brightness || Keylight.minBrightness
                            when: !brightSlider.pressed
                        }
                        onMoved: Keylight.setBrightness(block.modelData, brightSlider.value)
                    }
                }
            }
        }
    }
}
