import QtQuick

Rectangle {
    id: pill

    default property alias data: contentContainer.data
    property int contentPadding: Theme.padding
    property bool interactive: false
    property string tooltipText: ""

    signal leftClicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolledUp()
    signal scrolledDown()

    color: Theme.defaultBg
    radius: Theme.pillRadius
    implicitHeight: Theme.pillHeight
    implicitWidth: contentContainer.implicitWidth + contentPadding * 2

    Item {
        id: contentContainer
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        z: 10
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: pill.interactive || pill.tooltipText.length > 0
        cursorShape: pill.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: pill.interactive
        propagateComposedEvents: !pill.interactive

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) pill.leftClicked()
            else if (mouse.button === Qt.RightButton) pill.rightClicked()
            else if (mouse.button === Qt.MiddleButton) pill.middleClicked()
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) pill.scrolledUp()
            else if (wheel.angleDelta.y < 0) pill.scrolledDown()
            wheel.accepted = true
        }
    }
}
