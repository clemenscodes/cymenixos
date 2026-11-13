pragma Singleton

// Night light and software dimming through hyprsunset (Hyprland CTM protocol).
//
//   NightLight.available   — hyprsunset is reachable over hyprctl
//   NightLight.warm        — warm colour temperature active (false = neutral)
//   NightLight.temperature — warm temperature in K
//   NightLight.brightness  — brightness in percent, applied as CTM gain
//
// hyprsunset holds the state; this singleton starts it neutral (`hyprsunset -i`)
// unless one is already running, and pushes changes over its IPC. Changes are
// coalesced so dragging a slider does not spawn a hyprctl per pixel.
//
// Keybinds reach it through `qs ipc -c cymenix call nightlight <function>`, so the
// pill always shows the real state. Brightness may go down to black; the reset
// keybind is the way back without seeing anything.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property int minTemperature: 2500
    readonly property int maxTemperature: 6500
    readonly property int minBrightness: 0
    readonly property int brightnessStep: 5
    readonly property int temperatureStep: 250

    property bool available: false
    property bool warm: false
    property int temperature: 3400
    property int brightness: 100

    function setWarm(on) {
        root.warm = on
        root._schedule()
    }

    function toggleWarm() { root.setWarm(!root.warm) }

    function setTemperature(k) {
        root.temperature = Math.max(root.minTemperature, Math.min(root.maxTemperature, Math.round(k / 50) * 50))
        if (root.warm) root._schedule()
    }

    function setBrightness(p) {
        root.brightness = Math.max(root.minBrightness, Math.min(100, Math.round(p)))
        root._schedule()
    }

    function reset() {
        root.warm = false
        root.brightness = 100
        root._schedule()
    }

    // Turns the monitor off (DPMS); everything keeps running. The delay lets the
    // click that triggered it finish, so it does not wake the display right away.
    function displayOff() {
        Quickshell.execDetached(["sh", "-c", "sleep 1.5; hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'"])
    }

    // ----- push state to hyprsunset (coalesced) -----

    property bool _dirty: false

    function _schedule() {
        root._dirty = true
        if (!applyProc.running) applyTimer.restart()
    }

    function _apply() {
        if (!root.available || !root._dirty) return
        root._dirty = false
        const colour = root.warm ? "hyprctl hyprsunset temperature " + root.temperature : "hyprctl hyprsunset identity"
        applyProc.command = ["sh", "-c", colour + " >/dev/null && hyprctl hyprsunset gamma " + root.brightness + " >/dev/null"]
        applyProc.running = true
    }

    readonly property Timer _applyTimer: Timer {
        id: applyTimer
        interval: 40
        onTriggered: root._apply()
    }

    readonly property Process _applyProc: Process {
        id: applyProc
        onExited: { if (root._dirty) applyTimer.restart() }
    }

    // ----- keybinds -----

    readonly property IpcHandler _ipc: IpcHandler {
        target: "nightlight"

        function brighter(): void { root.setBrightness(root.brightness + root.brightnessStep) }
        function darker(): void { root.setBrightness(root.brightness - root.brightnessStep) }
        function warmer(): void {
            root.setTemperature(root.temperature - root.temperatureStep)
            if (!root.warm) root.setWarm(true)
        }
        function cooler(): void {
            root.setTemperature(root.temperature + root.temperatureStep)
            if (!root.warm) root.setWarm(true)
        }
        function toggleWarm(): void { root.toggleWarm() }
        function reset(): void { root.reset() }
        function displayOff(): void { root.displayOff() }
    }

    // ----- hyprsunset daemon -----

    // Probe for a running hyprsunset; start our own neutral one if there is none.
    readonly property Process _probe: Process {
        id: probe
        command: ["hyprctl", "hyprsunset", "gamma"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const reachable = !isNaN(parseFloat(this.text.trim()))
                if (reachable) {
                    root.available = true
                    root._dirty = true
                    root._apply()
                } else if (!daemon.running) {
                    daemon.running = true
                    probeTimer.restart()
                }
            }
        }
    }

    readonly property Timer _probeTimer: Timer {
        id: probeTimer
        interval: 1000
        onTriggered: probe.running = true
    }

    readonly property Process _daemon: Process {
        id: daemon
        command: ["hyprsunset", "-i"]
        onExited: {
            root.available = false
            retryTimer.restart()
        }
    }

    // hyprsunset exits when Hyprland restarts; look again after a pause.
    readonly property Timer _retryTimer: Timer {
        id: retryTimer
        interval: 5000
        onTriggered: probe.running = true
    }
}
