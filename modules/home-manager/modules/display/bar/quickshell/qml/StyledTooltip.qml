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

    TextMetrics {
        id: lineMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
    }

    function measureWidestLine(s) {
        if (!s || s.length === 0) return 0
        const lines = s.split("\n")
        let maxW = 0
        for (let i = 0; i < lines.length; i++) {
            lineMetrics.text = lines[i]
            const w = lineMetrics.boundingRect.width
            if (w > maxW) maxW = w
        }
        return maxW
    }

    readonly property real measuredNaturalWidth: measureWidestLine(tooltip.text)
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
