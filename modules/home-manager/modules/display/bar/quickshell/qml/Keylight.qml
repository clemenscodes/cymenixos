pragma Singleton

// Elgato Key Lights through a `keylight` command the host provides. Every subcommand
// (status, on, off, brightness <n>, temperature <kelvin>, optionally for one light with
// -l <name>) prints the resulting state as
//   {"lights":[{"name":"left","available":true,"on":true,"brightness":30,"temperature":4700}]}
//
//   Keylight.available  — `keylight` exists and at least one light answered
//   Keylight.names      — light names, in the order `keylight` reports them
//   Keylight.lights     — state per light, see above
//   Keylight.on         — at least one light is on
//   Keylight.brightness — mean brightness of the lights that are on
//
// The lights are the source of truth; they are polled to pick up changes from their own
// buttons or other tools.
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property int minBrightness: 3
    readonly property int minTemperature: 2900
    readonly property int maxTemperature: 7000

    property var names: []
    property var lights: []

    readonly property var reachable: root.lights.filter(l => l.available)
    readonly property bool available: root.reachable.length > 0
    readonly property bool on: root.reachable.some(l => l.on)
    readonly property int brightness: {
        const lit = root.reachable.filter(l => l.on)
        if (lit.length === 0) return 0
        return Math.round(lit.reduce((sum, l) => sum + l.brightness, 0) / lit.length)
    }

    function light(name) {
        return root.lights.find(l => l.name === name) || ({ name: name, available: false })
    }

    // Optimistic: show the new state at once, the command result and the poll correct it.

    // All lights together: off when any is on, otherwise on.
    function toggle() {
        const target = !root.on
        root._patch(null, { on: target })
        root._queue("all:on", ["keylight", target ? "on" : "off"])
    }

    function toggleLight(name) {
        const target = !root.light(name).on
        root._patch(name, { on: target })
        root._queue(name + ":on", ["keylight", "-l", name, target ? "on" : "off"])
    }

    function setBrightness(name, value) {
        const v = Math.max(root.minBrightness, Math.min(100, Math.round(value)))
        root._patch(name, { brightness: v })
        root._queue(name + ":brightness", ["keylight", "-l", name, "brightness", String(v)])
    }

    function setTemperature(name, value) {
        const v = Math.max(root.minTemperature, Math.min(root.maxTemperature, Math.round(value)))
        root._patch(name, { temperature: v })
        root._queue(name + ":temperature", ["keylight", "-l", name, "temperature", String(v)])
    }

    // Every light by the same step, so their difference stays.
    function changeBrightness(delta) {
        for (const l of root.reachable) root.setBrightness(l.name, l.brightness + delta)
    }

    // name null patches every light
    function _patch(name, changes) {
        root.lights = root.lights.map(l =>
            (name === null || l.name === name) && l.available ? Object.assign({}, l, changes) : l)
    }

    // ----- command runner (one at a time; per light and setting only the latest value) -----

    property var _pending: ({})

    function _queue(key, command) {
        const pending = Object.assign({}, root._pending)
        delete pending[key]
        pending[key] = command
        root._pending = pending
        if (!runProc.running) root._flush()
    }

    function _flush() {
        const keys = Object.keys(root._pending)
        if (keys.length === 0) return
        const pending = Object.assign({}, root._pending)
        runProc.command = pending[keys[0]]
        delete pending[keys[0]]
        root._pending = pending
        runProc.running = true
    }

    // Merges the reported lights by name; a status reports all of them and sets the order.
    function _parse(text, full) {
        const lines = text.split("\n").map(l => l.trim()).filter(l => l.startsWith("{"))
        if (lines.length === 0) return false
        let reported
        try {
            reported = JSON.parse(lines[lines.length - 1]).lights
        } catch (e) {
            return false
        }
        if (!Array.isArray(reported)) return false
        if (full) {
            const names = reported.map(l => l.name)
            if (names.join("\n") !== root.names.join("\n")) root.names = names
            root.lights = reported
        } else {
            root.lights = root.lights.map(l => reported.find(r => r.name === l.name) || l)
        }
        return true
    }

    readonly property Process _runProc: Process {
        id: runProc
        stdout: StdioCollector {
            // A stale answer would undo a newer optimistic value, so only the last one counts.
            onStreamFinished: { if (Object.keys(root._pending).length === 0) root._parse(this.text, false) }
        }
        onExited: root._flush()
    }

    readonly property Process _statusProc: Process {
        id: statusProc
        command: ["keylight", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                // A change sent meanwhile is newer than this answer.
                if (runProc.running || Object.keys(root._pending).length > 0) return
                if (!root._parse(this.text, true)) root.lights = []
            }
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
