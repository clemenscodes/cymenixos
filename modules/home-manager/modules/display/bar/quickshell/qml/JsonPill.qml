import QtQuick
import Quickshell.Io

Pill {
    id: root

    property var command: []
    property int intervalMs: 0
    property bool streaming: false
    property string fallbackText: ""
    property color textColor: Theme.textColor
    property var onLeftClick: null
    property var onRightClick: null
    property var onMiddleClick: null
    property var onScrollUp: null
    property var onScrollDown: null

    property string text: fallbackText
    property string altClass: ""
    property string tooltipText: ""
    property string iconName: ""

    visible: text.length > 0

    function parseLine(line) {
        try {
            const obj = JSON.parse(line)
            root.text = obj.text || ""
            root.altClass = obj.class || ""
            root.tooltipText = obj.tooltip || ""
            root.iconName = obj.alt || ""
        } catch (e) {
            root.text = line.trim()
        }
    }

    Process {
        id: streamProc
        command: root.command
        running: root.streaming && root.command.length > 0
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) { root.parseLine(line) }
        }
    }

    Process {
        id: pollProc
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: root.parseLine(this.text)
        }
    }

    Timer {
        running: !root.streaming && root.intervalMs > 0 && root.command.length > 0
        interval: root.intervalMs
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    Component.onCompleted: {
        if (!root.streaming && root.intervalMs === 0 && root.command.length > 0) {
            pollProc.running = true
        }
    }

    Item {
        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight

        Text {
            id: label
            text: root.text
            color: {
                if (root.altClass === "critical") return Theme.criticalColor
                if (root.altClass === "warning") return Theme.warningColor
                if (root.altClass === "inactive") return Theme.mutedColor
                return root.textColor
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: (root.onLeftClick || root.onRightClick || root.onMiddleClick) ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton && root.onLeftClick) root.onLeftClick()
                else if (mouse.button === Qt.RightButton && root.onRightClick) root.onRightClick()
                else if (mouse.button === Qt.MiddleButton && root.onMiddleClick) root.onMiddleClick()
            }
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0 && root.onScrollUp) root.onScrollUp()
                else if (wheel.angleDelta.y < 0 && root.onScrollDown) root.onScrollDown()
                wheel.accepted = true
            }
        }
    }
}
