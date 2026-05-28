import QtQuick
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
    property string iconName: ""

    interactive: onLeftClick !== null || onRightClick !== null || onMiddleClick !== null

    readonly property string displayText: {
        const keys = Object.keys(root.formatIcons)
        if (keys.length === 0) return root.text
        if (root.iconName && root.formatIcons[root.iconName] !== undefined) return root.formatIcons[root.iconName]
        if (root.formatIcons.default !== undefined) return root.formatIcons.default
        return root.text
    }

    visible: displayText.length > 0

    onLeftClicked: { if (root.onLeftClick) root.onLeftClick() }
    onRightClicked: { if (root.onRightClick) root.onRightClick() }
    onMiddleClicked: { if (root.onMiddleClick) root.onMiddleClick() }
    onScrolledUp: { if (root.onScrollUp) root.onScrollUp() }
    onScrolledDown: { if (root.onScrollDown) root.onScrollDown() }

    function parseLine(line) {
        if (!line) return
        const trimmed = line.trim()
        if (trimmed.length === 0) return
        if (trimmed.startsWith("{")) {
            try {
                const obj = JSON.parse(trimmed)
                root.text = obj.text || ""
                root.altClass = obj.class || ""
                root.iconName = obj.alt || ""
                return
            } catch (e) {}
        }
        const lines = line.split("\n")
        root.text = (lines[0] || "").trim()
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
}
