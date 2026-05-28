import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

PanelWindow {
    id: launcher

    property string query: ""
    property int selectedIndex: 0

    readonly property int cardWidth: 620
    readonly property int cardHeight: 560

    visible: false
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: 0
    aboveWindows: true
    focusable: true

    function toggle(window) {
        if (launcher.visible) launcher.hide()
        else launcher.show(window)
    }

    function show(window) {
        if (window && window.screen) launcher.screen = window.screen
        launcher.selectedIndex = 0
        input.text = ""
        launcher.visible = true
        Qt.callLater(() => input.forceActiveFocus())
    }

    function hide() {
        launcher.visible = false
    }

    readonly property var allApps: {
        const apps = DesktopEntries.applications.values
        const out = []
        for (let i = 0; i < apps.length; i++) {
            const a = apps[i]
            if (!a.noDisplay) out.push(a)
        }
        out.sort((a, b) => a.name.localeCompare(b.name))
        return out
    }

    function score(entry, q) {
        const name = (entry.name || "").toLowerCase()
        const generic = (entry.genericName || "").toLowerCase()
        const comment = (entry.comment || "").toLowerCase()
        if (name === q) return 1000
        if (name.startsWith(q)) return 900
        const nameIdx = name.indexOf(q)
        if (nameIdx >= 0) return 700 - nameIdx
        if (generic.startsWith(q)) return 600
        if (generic.indexOf(q) >= 0) return 500
        if (comment.indexOf(q) >= 0) return 200
        return -1
    }

    readonly property var filtered: {
        const q = launcher.query.toLowerCase().trim()
        if (q.length === 0) return launcher.allApps.slice(0, 250)
        const scored = []
        for (let i = 0; i < launcher.allApps.length; i++) {
            const a = launcher.allApps[i]
            const s = launcher.score(a, q)
            if (s >= 0) scored.push({ entry: a, score: s })
        }
        scored.sort((a, b) => b.score - a.score)
        return scored.map(x => x.entry)
    }

    onFilteredChanged: launcher.selectedIndex = 0

    function launch(index) {
        const items = launcher.filtered
        const i = index !== undefined ? index : launcher.selectedIndex
        if (i >= 0 && i < items.length) {
            items[i].execute()
        }
        launcher.hide()
    }

    // Backdrop: click outside the card dismisses.
    MouseArea {
        anchors.fill: parent
        onClicked: launcher.hide()
    }

    // Card.
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: launcher.cardWidth
        height: launcher.cardHeight
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        // Swallow clicks on the card itself so backdrop doesn't dismiss
        // when the user clicks empty padding between fields.
        MouseArea {
            anchors.fill: parent
            onClicked: { /* eat */ }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: Theme.innerRadius
                color: Qt.lighter(Theme.defaultBg, 1.25)
                border.color: input.activeFocus ? Theme.activeBg : "transparent"
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: Theme.fadeMs / 2 }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "🔍"
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    TextField {
                        id: input
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 32
                        background: null
                        color: Theme.textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        placeholderText: "Search applications…"
                        placeholderTextColor: Qt.darker(Theme.textColor, 1.6)
                        selectByMouse: true
                        onTextChanged: launcher.query = text
                        focus: true

                        Keys.onPressed: function(event) {
                            const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
                            const last = launcher.filtered.length - 1
                            if (event.key === Qt.Key_Escape) {
                                launcher.hide()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                launcher.launch()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down
                                    || event.key === Qt.Key_Tab
                                    || (ctrl && event.key === Qt.Key_J)
                                    || (ctrl && event.key === Qt.Key_N)) {
                                launcher.selectedIndex = Math.min(last, launcher.selectedIndex + 1)
                                resultList.positionViewAtIndex(launcher.selectedIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up
                                    || event.key === Qt.Key_Backtab
                                    || (ctrl && event.key === Qt.Key_K)
                                    || (ctrl && event.key === Qt.Key_P)) {
                                launcher.selectedIndex = Math.max(0, launcher.selectedIndex - 1)
                                resultList.positionViewAtIndex(launcher.selectedIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_PageDown
                                    || (ctrl && event.key === Qt.Key_D)) {
                                launcher.selectedIndex = Math.min(last, launcher.selectedIndex + 8)
                                resultList.positionViewAtIndex(launcher.selectedIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_PageUp
                                    || (ctrl && event.key === Qt.Key_U)) {
                                launcher.selectedIndex = Math.max(0, launcher.selectedIndex - 8)
                                resultList.positionViewAtIndex(launcher.selectedIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Home
                                    || (ctrl && event.key === Qt.Key_Home)) {
                                launcher.selectedIndex = 0
                                resultList.positionViewAtIndex(0, ListView.Beginning)
                                event.accepted = true
                            } else if (event.key === Qt.Key_End
                                    || (ctrl && event.key === Qt.Key_End)) {
                                launcher.selectedIndex = last
                                resultList.positionViewAtIndex(last, ListView.End)
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: launcher.filtered
                highlightFollowsCurrentItem: false
                currentIndex: launcher.selectedIndex

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 56
                    radius: Theme.innerRadius
                    color: index === launcher.selectedIndex
                        ? Qt.lighter(Theme.defaultBg, 1.4)
                        : (rowHover.containsMouse
                            ? Qt.lighter(Theme.defaultBg, 1.2)
                            : Theme.defaultBg)

                    Behavior on color {
                        ColorAnimation { duration: Theme.fadeMs / 2 }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 14

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 36
                            source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                            smooth: true
                            mipmap: true
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 64
                            spacing: 2

                            Text {
                                text: row.modelData.name || ""
                                color: Theme.textColor
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: row.index === launcher.selectedIndex
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: row.modelData.genericName || row.modelData.comment || ""
                                color: Qt.darker(Theme.textColor, 1.6)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 4
                                elide: Text.ElideRight
                                width: parent.width
                                visible: text.length > 0
                            }
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: launcher.selectedIndex = row.index
                        onClicked: launcher.launch(row.index)
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }

            Text {
                Layout.fillWidth: true
                text: launcher.filtered.length + " application"
                    + (launcher.filtered.length === 1 ? "" : "s")
                color: Qt.darker(Theme.textColor, 1.6)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 4
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            launcher.toggle(null)
        }

        function open() {
            launcher.show(null)
        }

        function close() {
            launcher.hide()
        }
    }
}
