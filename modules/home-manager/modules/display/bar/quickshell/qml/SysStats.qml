pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: stats

    property int cpuPercent: 0
    property int memPercent: 0
    property string diskUsage: ""
    property int tempC: 0

    property int _prevTotal: 0
    property int _prevIdle: 0

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

    readonly property Timer _diskTick: Timer {
        running: true
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    readonly property Process _cpuProc: Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(/\s+/)
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
            }
        }
    }

    readonly property Process _memProc: Process {
        id: memProc
        command: ["sh", "-c", "head -3 /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, avail = 0
                this.text.split("\n").forEach(function(l) {
                    const m = l.match(/^(\w+):\s+(\d+)/)
                    if (!m) return
                    if (m[1] === "MemTotal") total = parseInt(m[2])
                    else if (m[1] === "MemAvailable") avail = parseInt(m[2])
                })
                if (total > 0) {
                    stats.memPercent = Math.round(100 * (total - avail) / total)
                }
            }
        }
    }

    readonly property Process _diskProc: Process {
        id: diskProc
        command: ["sh", "-c", "df -h / | awk 'NR==2 {print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: stats.diskUsage = this.text.trim()
        }
    }

    readonly property Process _tempProc: Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 || cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text.trim())
                if (!isNaN(v)) stats.tempC = Math.round(v / 1000)
            }
        }
    }
}
