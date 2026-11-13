pragma Singleton

// RGB lighting through the rgb-* commands of the cymenixos rgb module (OpenRGB SDK servers).
//
//   Rgb.available  — the rgb-* commands exist on this machine
//   Rgb.on         — lighting is on (declared modes) or off
//   Rgb.brightness — global brightness in percent; only devices whose effects have a
//                    brightness range follow it, the others only switch on and off
//
// The state file of rgb-control is the source of truth, so keybinds, timers and the bar
// agree; it is polled to pick up changes made elsewhere.
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property int brightnessStep: 25

    property bool available: false
    property bool on: true
    property int brightness: 100
    property bool busy: runProc.running

    // Optimistic: show the new state at once, the command result and the poll correct it.
    function toggle() {
        if (runProc.running) return
        root.on = !root.on
        root._run(["rgb-toggle"])
    }

    function changeBrightness(delta) {
        root.brightness = Math.max(0, Math.min(100, root.brightness + delta))
        root._pendingBrightness = root.brightness
        if (!runProc.running) root._flush()
    }

    // ----- command runner (one at a time; brightness changes are coalesced) -----

    property int _pendingBrightness: -1

    function _run(command) {
        if (runProc.running) return
        runProc.command = command
        runProc.running = true
    }

    function _flush() {
        if (root._pendingBrightness < 0) return
        const value = root._pendingBrightness
        root._pendingBrightness = -1
        root._run(["rgb-brightness", String(value)])
    }

    function _parse(text) {
        const lines = text.split("\n").map(l => l.trim()).filter(l => l.startsWith("{"))
        if (lines.length === 0) return false
        try {
            const state = JSON.parse(lines[lines.length - 1])
            root.on = state.on
            root.brightness = state.brightness
            root.available = true
            return true
        } catch (e) {
            return false
        }
    }

    readonly property Process _runProc: Process {
        id: runProc
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
        onExited: root._flush()
    }

    readonly property Process _statusProc: Process {
        id: statusProc
        command: ["rgb-status"]
        stdout: StdioCollector {
            onStreamFinished: { if (!root._parse(this.text)) root.available = false }
        }
    }

    readonly property Timer _poll: Timer {
        running: true
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!runProc.running && !statusProc.running) statusProc.running = true }
    }
}
