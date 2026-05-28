import QtQuick

Rectangle {
    id: pill

    default property alias data: contentContainer.data
    property int contentPadding: Theme.padding
    property alias contentItem: contentContainer

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
}
