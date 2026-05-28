import QtQuick

Rectangle {
    id: pill

    property alias content: contentItem.children
    property int horizontalPadding: Theme.padding
    property int verticalPadding: 0

    color: Theme.defaultBg
    radius: Theme.pillRadius
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.leftMargin: pill.horizontalPadding
        anchors.rightMargin: pill.horizontalPadding
        anchors.topMargin: pill.verticalPadding
        anchors.bottomMargin: pill.verticalPadding
        implicitHeight: childrenRect.height
        implicitWidth: childrenRect.width
    }
}
