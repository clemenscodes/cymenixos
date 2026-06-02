pragma Singleton

// Display backlight brightness, driven by brightnessctl.
//
//   Brightness.available — true only when a screen backlight device exists
//                          (i.e. laptops); the pill hides itself otherwise.
//   Brightness.percent   — current brightness 0..100
//   Brightness.device    — backlight device name (for tooltips)
//
// External changes (XF86 brightness keys) are picked up by the poll timer.
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available: false
    property int percent: 0
    property string device: ""

    function _refresh() { infoProc.running = true }

    function setPercent(p) {
        const clamped = Math.max(1, Math.min(100, Math.round(p)))
        setProc.command = ["brightnessctl", "-m", "set", clamped + "%"]
        setProc.running = true
    }

    function increase(delta) { root.setPercent(root.percent + delta) }
    function decrease(delta) { root.setPercent(root.percent - delta) }

    // brightnessctl -m output: device,class,current,percent,max
    // e.g. "intel_backlight,backlight,12000,80%,15000"
    function _parse(text) {
        const line = text.split("\n").map(l => l.trim()).filter(l => l.length > 0)[0]
        if (!line) { root.available = false; return }
        const parts = line.split(",")
        if (parts.length < 5 || parts[1] !== "backlight") { root.available = false; return }
        const pct = parseInt(parts[3].replace("%", ""))
        if (isNaN(pct)) { root.available = false; return }
        root.device = parts[0]
        root.percent = pct
        root.available = true
    }

    readonly property Timer _poll: Timer {
        running: true
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root._refresh()
    }

    readonly property Process _infoProc: Process {
        id: infoProc
        command: ["brightnessctl", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
    }

    readonly property Process _setProc: Process {
        id: setProc
        command: ["brightnessctl", "-m", "set", "50%"]
        // -m set also echoes the device line, so reuse it for instant feedback.
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
    }
}
