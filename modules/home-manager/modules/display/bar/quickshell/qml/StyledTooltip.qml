import QtQuick
import Quickshell

PopupWindow {
    id: tooltip

    property string text: ""
    property Item targetItem: null
    property var targetWindow: null
    property int verticalGap: 8
    property string placement: "above"

    readonly property int innerPadding: 12
    readonly property int outerPadding: 8

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

        implicitWidth: tooltipText.implicitWidth + tooltip.innerPadding * 2
        implicitHeight: tooltipText.implicitHeight + tooltip.outerPadding * 2

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: tooltip.text
            color: Theme.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            wrapMode: Text.NoWrap
        }
    }
}
