import QtQuick
import Quickshell

PopupWindow {
    id: tooltip

    property string text: ""
    property Item targetItem: null
    property var targetWindow: null
    property int maxWidth: 720
    property int verticalGap: 8
    property string placement: "above"

    readonly property int innerPadding: 12
    readonly property int outerPadding: 8

    color: "transparent"
    visible: false

    Text {
        id: naturalMeasure
        text: tooltip.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        wrapMode: Text.NoWrap
        visible: false
    }

    readonly property real measuredNaturalWidth: naturalMeasure.contentWidth
    readonly property real fitWidth: Math.min(measuredNaturalWidth + innerPadding * 2, maxWidth)

    implicitWidth: fitWidth
    implicitHeight: tooltipText.contentHeight + outerPadding * 2

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
        anchors.fill: parent
        color: Theme.defaultBg
        radius: 8
        border.color: Theme.activeBg
        border.width: 1

        Text {
            id: tooltipText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: tooltip.innerPadding
            anchors.rightMargin: tooltip.innerPadding
            text: tooltip.text
            color: Theme.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            wrapMode: Text.Wrap
        }
    }
}
