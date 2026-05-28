import QtQuick
import Quickshell

PopupWindow {
    id: popup

    property var trayItem: null
    property Item anchorItem: null
    property var anchorWindow: null

    color: "transparent"
    grabFocus: true

    implicitWidth: 240
    implicitHeight: menuFrame.implicitHeight

    anchor {
        window: popup.anchorWindow
        rect.x: popup.anchorItem
            ? popup.anchorItem.mapToItem(null, 0, 0).x + popup.anchorItem.width / 2 - popup.implicitWidth / 2
            : 0
        rect.y: 0
        rect.width: 1
        rect.height: 1
        edges: Edges.Top
        gravity: Edges.Top
    }

    QsMenuOpener {
        id: opener
        menu: popup.trayItem ? popup.trayItem.menu : null
    }

    function show(item, item2, window) {
        popup.trayItem = item
        popup.anchorItem = item2
        popup.anchorWindow = window
        popup.visible = true
    }

    Rectangle {
        id: menuFrame
        anchors.fill: parent
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1
        implicitHeight: menuColumn.implicitHeight + 12

        Column {
            id: menuColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: opener.children

                delegate: Item {
                    id: entry
                    required property var modelData
                    width: menuColumn.width
                    implicitHeight: modelData && modelData.isSeparator ? 9 : 30

                    Rectangle {
                        visible: entry.modelData && entry.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: "#555"
                    }

                    Rectangle {
                        visible: entry.modelData && !entry.modelData.isSeparator
                        anchors.fill: parent
                        color: itemHover.containsMouse ? Theme.activeBg : "transparent"
                        radius: Theme.innerRadius

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Image {
                                width: 16
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                visible: entry.modelData && entry.modelData.icon !== ""
                                source: entry.modelData ? entry.modelData.icon : ""
                                sourceSize.width: 16
                                sourceSize.height: 16
                                smooth: true
                                mipmap: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData ? entry.modelData.text : ""
                                color: !entry.modelData || !entry.modelData.enabled
                                    ? Theme.mutedColor
                                    : (itemHover.containsMouse ? Theme.activeTextColor : Theme.textColor)
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: itemHover.containsMouse
                            }
                        }

                        MouseArea {
                            id: itemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: entry.modelData && entry.modelData.enabled && !entry.modelData.isSeparator
                            onClicked: {
                                entry.modelData.triggered()
                                popup.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
