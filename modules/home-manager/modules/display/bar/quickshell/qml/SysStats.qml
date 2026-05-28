pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: stats

    // -------- short values for pill text --------

    property int cpuPercent: 0
    property int memPercent: 0
    property string diskUsage: ""
    property int tempC: 0

    // -------- detail for tooltips --------

    property string cpuModel: ""
    property int cpuCores: 0
    property real loadAvg1: 0
    property real loadAvg5: 0
    property real loadAvg15: 0

    property real memTotalGib: 0
    property real memUsedGib: 0
    property real memAvailGib: 0
    property real memCachedGib: 0
    property real swapTotalGib: 0
    property real swapUsedGib: 0

    property string diskFs: ""
    property string diskSize: ""
    property string diskUsed: ""
    property string diskAvail: ""
    property string diskMount: ""

    property var perCoreTempC: ({})

    // -------- internal state --------

    property int _prevTotal: 0
    property int _prevIdle: 0

    readonly property string cpuTooltip: {
        let s = stats.cpuModel || "CPU"
        if (stats.cpuCores > 0) s += " · " + stats.cpuCores + " cores"
        s += "\nUsage:      " + stats.cpuPercent + "%"
        s += "\nLoad avg:   " + stats.loadAvg1.toFixed(2)
              + "  " + stats.loadAvg5.toFixed(2)
              + "  " + stats.loadAvg15.toFixed(2)
              + "   (1 / 5 / 15 min)"
        return s
    }

    readonly property string memTooltip: {
        const usedPct = stats.memPercent
        let s = "Memory      " + usedPct + "%"
        s += "\nUsed:       " + stats.memUsedGib.toFixed(2) + " GiB"
        s += "\nAvailable:  " + stats.memAvailGib.toFixed(2) + " GiB"
        s += "\nCached:     " + stats.memCachedGib.toFixed(2) + " GiB"
        s += "\nTotal:      " + stats.memTotalGib.toFixed(2) + " GiB"
        if (stats.swapTotalGib > 0) {
            const swapPct = stats.swapTotalGib > 0
                ? Math.round(100 * stats.swapUsedGib / stats.swapTotalGib)
                : 0
            s += "\n\nSwap " + swapPct + "%:  "
                  + stats.swapUsedGib.toFixed(2) + " / "
                  + stats.swapTotalGib.toFixed(2) + " GiB"
        }
        return s
    }

    readonly property string diskTooltip: {
        let s = "Disk " + (stats.diskMount || "/")
        if (stats.diskFs) s += "  (" + stats.diskFs + ")"
        s += "\nUsed:       " + (stats.diskUsed || "?")
        s += "\nFree:       " + (stats.diskAvail || "?")
        s += "\nTotal:      " + (stats.diskSize || "?")
        s += "\nIn use:     " + (stats.diskUsage || "?")
        return s
    }

    readonly property string tempTooltip: {
        let s = "CPU temperature  " + stats.tempC + "°C"
        const cores = Object.keys(stats.perCoreTempC)
        if (cores.length > 0) {
            s += "\n"
            cores.sort()
            for (let i = 0; i < cores.length; i++) {
                s += "\n" + cores[i].padEnd(10) + " " + stats.perCoreTempC[cores[i]] + "°C"
            }
        }
        return s
    }

    // -------- pollers --------

    readonly property Timer _tick: Timer {
        running: true
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            tempProc.running = true
        }
    }

    readonly property Timer _slowTick: Timer {
        running: true
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            diskProc.running = true
            cpuInfoProc.running = true
        }
    }

    readonly property Process _cpuProc: Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat; cat /proc/loadavg"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                if (lines.length < 1) return
                const parts = lines[0].trim().split(/\s+/)
                if (parts.length < 5) return
                const user = parseInt(parts[1]) || 0
                const nice = parseInt(parts[2]) || 0
                const sys = parseInt(parts[3]) || 0
                const idle = parseInt(parts[4]) || 0
                const iowait = parseInt(parts[5]) || 0
                const total = user + nice + sys + idle + iowait
                const idleAll = idle + iowait
                const dTotal = total - stats._prevTotal
                const dIdle = idleAll - stats._prevIdle
                if (stats._prevTotal > 0 && dTotal > 0) {
                    stats.cpuPercent = Math.round(100 * (dTotal - dIdle) / dTotal)
                }
                stats._prevTotal = total
                stats._prevIdle = idleAll

                if (lines.length >= 2) {
                    const lp = lines[1].trim().split(/\s+/)
                    stats.loadAvg1 = parseFloat(lp[0]) || 0
                    stats.loadAvg5 = parseFloat(lp[1]) || 0
                    stats.loadAvg15 = parseFloat(lp[2]) || 0
                }
            }
        }
    }

    readonly property Process _cpuInfoProc: Process {
        id: cpuInfoProc
        command: ["sh", "-c", "grep -m1 'model name' /proc/cpuinfo; grep -c '^processor' /proc/cpuinfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                if (lines.length >= 1) {
                    const m = lines[0].match(/model name\s*:\s*(.+)/)
                    if (m) stats.cpuModel = m[1].trim()
                }
                if (lines.length >= 2) {
                    const n = parseInt(lines[1].trim())
                    if (!isNaN(n)) stats.cpuCores = n
                }
            }
        }
    }

    readonly property Process _memProc: Process {
        id: memProc
        command: ["sh", "-c", "cat /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, avail = 0, cached = 0, free = 0
                let swapTotal = 0, swapFree = 0
                this.text.split("\n").forEach(function(l) {
                    const m = l.match(/^(\w+):\s+(\d+)/)
                    if (!m) return
                    const v = parseInt(m[2])
                    switch (m[1]) {
                        case "MemTotal": total = v; break
                        case "MemAvailable": avail = v; break
                        case "MemFree": free = v; break
                        case "Cached": cached = v; break
                        case "SwapTotal": swapTotal = v; break
                        case "SwapFree": swapFree = v; break
                    }
                })
                if (total > 0) {
                    const KiB_TO_GiB = 1.0 / (1024 * 1024)
                    stats.memTotalGib = total * KiB_TO_GiB
                    stats.memAvailGib = avail * KiB_TO_GiB
                    stats.memCachedGib = cached * KiB_TO_GiB
                    stats.memUsedGib = (total - avail) * KiB_TO_GiB
                    stats.memPercent = Math.round(100 * (total - avail) / total)
                    stats.swapTotalGib = swapTotal * KiB_TO_GiB
                    stats.swapUsedGib = (swapTotal - swapFree) * KiB_TO_GiB
                }
            }
        }
    }

    readonly property Process _diskProc: Process {
        id: diskProc
        command: ["sh", "-c", "df -h --output=fstype,size,used,avail,pcent,target / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(/\s+/)
                if (parts.length >= 6) {
                    stats.diskFs = parts[0]
                    stats.diskSize = parts[1]
                    stats.diskUsed = parts[2]
                    stats.diskAvail = parts[3]
                    stats.diskUsage = parts[4]
                    stats.diskMount = parts[5]
                }
            }
        }
    }

    readonly property Process _tempProc: Process {
        id: tempProc
        command: ["sh", "-c",
            "main=$(cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input 2>/dev/null | head -1); " +
            "if [ -z \"$main\" ]; then main=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1); fi; " +
            "echo \"main=$main\"; " +
            "for f in /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp[0-9]_label; do " +
            "  [ -f \"$f\" ] || continue; " +
            "  label=$(cat \"$f\" 2>/dev/null); " +
            "  inp=${f%_label}_input; " +
            "  v=$(cat \"$inp\" 2>/dev/null); " +
            "  [ -n \"$v\" ] && echo \"core $label=$v\"; " +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n")
                const cores = {}
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (line.startsWith("main=")) {
                        const v = parseInt(line.substring(5))
                        if (!isNaN(v)) stats.tempC = Math.round(v / 1000)
                    } else if (line.startsWith("core ")) {
                        const m = line.match(/^core\s+(.+?)=(\d+)$/)
                        if (m) {
                            const c = Math.round(parseInt(m[2]) / 1000)
                            cores[m[1]] = c
                        }
                    }
                }
                stats.perCoreTempC = cores
            }
        }
    }
}
