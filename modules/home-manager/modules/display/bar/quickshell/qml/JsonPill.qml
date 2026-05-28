import QtQuick
import QtQuick.Controls
import Quickshell.Io

Pill {
    id: root

    property var command: []
    property int intervalMs: 0
    property bool streaming: false
    property string fallbackText: ""
    property color textColor: Theme.textColor
    property var formatIcons: ({})
    property var onLeftClick: null
    property var onRightClick: null
    property var onMiddleClick: null
    property var onScrollUp: null
    property var onScrollDown: null

    property string text: fallbackText
    property string altClass: ""
    property string tooltipText: ""
    property string iconName: ""

    readonly property string displayText: {
        const keys = Object.keys(root.formatIcons)
        if (keys.length === 0) return root.text
        if (root.iconName && root.formatIcons[root.iconName] !== undefined) return root.formatIcons[root.iconName]
        if (root.formatIcons.default !== undefined) return root.formatIcons.default
        return root.text
    }

    visible: displayText.length > 0

    function parseLine(line) {
        if (!line) return
        const trimmed = line.trim()
        if (trimmed.length === 0) return
        if (trimmed.startsWith("{")) {
            try {
                const obj = JSON.parse(trimmed)
                root.text = obj.text || ""
                root.altClass = obj.class || ""
                root.tooltipText = obj.tooltip || ""
                root.iconName = obj.alt || ""
                return
            } catch (e) {}
        }
        const lines = line.split("\n")
        root.text = (lines[0] || "").trim()
        root.tooltipText = (lines[1] || "").trim()
        root.altClass = (lines[2] || "").trim()
        root.iconName = ""
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
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    root.parseLine(this.text)
                }
            }
        }
    }

    Timer {
        running: !root.streaming && root.intervalMs > 0 && root.command.length > 0
        interval: root.intervalMs
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.exec(root.command)
    }

    Component.onCompleted: {
        if (!root.streaming && root.intervalMs === 0 && root.command.length > 0) {
            pollProc.exec(root.command)
        }
    }

    Item {
        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight

        Text {
            id: label
            text: root.displayText
            color: {
                if (root.altClass === "critical" || root.altClass === "notification") return Theme.criticalColor
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
            hoverEnabled: root.tooltipText.length > 0
            cursorShape: (root.onLeftClick || root.onRightClick || root.onMiddleClick) ? Qt.PointingHandCursor : Qt.ArrowCursor

            ToolTip.visible: containsMouse && root.tooltipText.length > 0
            ToolTip.delay: 500
            ToolTip.text: root.tooltipText

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
