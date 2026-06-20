import QtQuick
import QtQuick.Controls
import Quickshell

// A small draggable slider popover anchored to a pill — for fine-grained
// control of brightness / volume / mic where scrolling is too coarse.
//
//   placement "above" — popover sits above the pill (bottom bar)
//   placement "below" — popover sits below the pill (top bar)
//
// Everything is expressed in integer percent so callers don't juggle ranges:
// brightness uses maxPercent 100, audio uses 150 (allowing boosted volume).
PopupWindow {
    id: popup

    property Item targetItem: null
    property var targetWindow: null
    property string placement: "above"
    property int verticalGap: 8

    property string iconText: ""
    property string headerText: ""
    property int percent: 0
    property int maxPercent: 100
    property bool showMute: false
    property bool muted: false

    signal moved(int value)
    signal muteToggled()

    color: "transparent"
    visible: false

    implicitWidth: 300
    implicitHeight: 92

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

    // ----- show / hide -----

    property bool hovered: false
    readonly property bool dragging: slider.pressed

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

    // Dismiss promptly once the pointer leaves the popover, unless dragging.
    // Short grace so moving from the pill up into the popover doesn't lose it.
    Timer {
        id: hideTimer
        interval: 1000
        onTriggered: { if (!popup.hovered && !popup.dragging) popup.hide() }
    }

    onDraggingChanged: { if (!dragging && !hovered) hideTimer.restart() }

    Rectangle {
        id: bg
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
            spacing: 10

            // ----- header: icon · label · percent -----
            Item {
                width: parent.width
                height: 22

                Text {
                    id: icon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.iconText
                    color: popup.muted ? Theme.mutedColor : Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: popup.showMute
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.muteToggled()
                    }
                }

                Text {
                    anchors.left: icon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: popup.headerText
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(slider.value) + "%"
                    color: Theme.activeBg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                }
            }

            // ----- slider -----
            Slider {
                id: slider
                width: parent.width
                height: 20
                from: 0
                to: popup.maxPercent
                stepSize: 1
                // Follow the live source, but release the binding while dragging
                // so the handle isn't fought by write-back — avoids jitter.
                Binding on value {
                    value: popup.percent
                    when: !slider.pressed
                }
                onMoved: popup.moved(Math.round(slider.value))

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: 8
                    radius: 4
                    color: Qt.darker(Theme.defaultBg, 1.7)

                    // 100% reference tick (only meaningful when boost is allowed)
                    Rectangle {
                        visible: popup.maxPercent > 100
                        width: 2
                        height: parent.height + 6
                        radius: 1
                        y: -3
                        x: (100 / popup.maxPercent) * parent.width - width / 2
                        color: Qt.darker(Theme.textColor, 2)
                    }

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 4
                        color: popup.muted ? Theme.mutedColor : Theme.activeBg
                    }
                }

                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 18
                    height: 18
                    radius: 9
                    color: slider.pressed ? Qt.lighter(Theme.activeBg, 1.15) : Theme.textColor
                    border.color: Theme.activeBg
                    border.width: 2
                }
            }
        }
    }
}
