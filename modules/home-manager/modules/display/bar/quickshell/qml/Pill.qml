import QtQuick

Rectangle {
    id: pill

    default property alias data: contentContainer.data
    property int contentPadding: Theme.padding
    property bool interactive: false

    property string tooltipText: ""
    property var tooltipHost: null
    property var tooltipHostWindow: null
    // Set true to keep the hover tooltip from showing — e.g. while this pill's
    // slider popover is open, so the two don't stack on top of each other.
    property bool tooltipSuppressed: false

    signal leftClicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolledUp()
    signal scrolledDown()
    // Notches scrolled this event: +1.0 per mouse-wheel detent, but a fraction
    // for touchpad scroll (which fires many small-delta events) — letting
    // handlers scale the change so a tiny touchpad swipe is a tiny adjustment.
    signal scrolledBy(real notches)

    property color baseColor: Theme.defaultBg
    property color hoverColor: Qt.lighter(baseColor, 1.4)

    readonly property bool _shouldHandleMouse: pill.interactive || pill.tooltipText.length > 0
    property bool _hovered: false

    color: (_hovered && _shouldHandleMouse) ? hoverColor : baseColor

    Behavior on color {
        ColorAnimation { duration: Theme.fadeMs / 2 }
    }

    radius: Theme.pillRadius
    implicitHeight: Theme.pillHeight
    implicitWidth: contentContainer.implicitWidth + contentPadding * 2

    Item {
        id: contentContainer
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    Loader {
        anchors.fill: parent
        z: 10
        active: pill._shouldHandleMouse

        sourceComponent: MouseArea {
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true
            cursorShape: pill.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: function(mouse) {
                if (!pill.interactive) return
                if (mouse.button === Qt.LeftButton) pill.leftClicked()
                else if (mouse.button === Qt.RightButton) pill.rightClicked()
                else if (mouse.button === Qt.MiddleButton) pill.middleClicked()
            }
            onWheel: function(wheel) {
                if (!pill.interactive) { wheel.accepted = false; return }
                if (wheel.angleDelta.y > 0) pill.scrolledUp()
                else if (wheel.angleDelta.y < 0) pill.scrolledDown()
                // 120 angle units == one mouse-wheel detent.
                pill.scrolledBy(wheel.angleDelta.y / 120)
                wheel.accepted = true
            }
            onEntered: {
                pill._hovered = true
                if (!pill.tooltipSuppressed && pill.tooltipText.length > 0 && pill.tooltipHost) {
                    pill.tooltipHost.showFor(pill, pill.tooltipText, pill.tooltipHostWindow)
                }
            }
            onExited: {
                pill._hovered = false
                if (pill.tooltipHost) pill.tooltipHost.hide()
            }
        }
    }
}
