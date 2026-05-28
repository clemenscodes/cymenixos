import QtQuick
import Quickshell

PopupWindow {
    id: tooltip

    property string text: ""
    property Item targetItem: null
    property var targetWindow: null
    property int maxWidth: 480
    property int verticalGap: 8
    property string placement: "above"

    color: "transparent"
    visible: false

    implicitWidth: contentBg.implicitWidth
    implicitHeight: contentBg.implicitHeight

    anchor {
        window: tooltip.targetWindow
        rect.x: tooltip.targetItem
            ? tooltip.targetItem.mapToItem(null, 0, 0).x + tooltip.targetItem.width / 2 - tooltip.implicitWidth / 2
            : 0
        rect.y: tooltip.placement === "above"
            ? -tooltip.verticalGap
            : (tooltip.targetWindow ? tooltip.targetWindow.height + tooltip.verticalGap : tooltip.verticalGap)
        rect.width: 1
        rect.height: 1
        edges: tooltip.placement === "above" ? Edges.Top : Edges.Bottom
        gravity: tooltip.placement === "above" ? Edges.Top : Edges.Bottom
    }

    function showFor(item, txt, window) {
        if (!txt || txt.length === 0) {
            tooltip.visible = false
            return
        }
        tooltip.text = txt
        tooltip.targetItem = item
        tooltip.targetWindow = window
        tooltip.visible = true
    }

    function hide() {
        tooltip.visible = false
    }

    Rectangle {
        id: contentBg
        anchors.fill: parent
        color: Theme.defaultBg
        radius: 8
        border.color: Theme.activeBg
        border.width: 1

        implicitWidth: Math.min(tooltipText.implicitWidth + 24, tooltip.maxWidth)
        implicitHeight: tooltipText.implicitHeight + 16

        Text {
            id: tooltipText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            text: tooltip.text
            color: Theme.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            wrapMode: Text.Wrap
        }
    }
}
