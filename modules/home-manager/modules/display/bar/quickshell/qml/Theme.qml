pragma Singleton
import QtQuick

QtObject {
    readonly property color defaultBg: "#4A3C63"
    readonly property color activeBg: "#D8C1C4"
    readonly property color urgentBg: "#eb4d4b"
    readonly property color textColor: "#ffffff"
    readonly property color activeTextColor: "#58505E"
    readonly property color powerBg: "#f53c3c"
    readonly property color warningColor: "#f1fa8c"
    readonly property color criticalColor: "#ff5555"
    readonly property color mutedColor: "#6272a4"

    readonly property int barHeight: 60
    readonly property int barMargin: 12
    readonly property int pillRadius: 12
    readonly property int innerRadius: 8
    readonly property int pillSpacing: 4
    readonly property int padding: 12

    readonly property string fontFamily: "Iosevka Nerd Font Mono"
    readonly property int fontSize: 16

    readonly property int fadeMs: 300
}
