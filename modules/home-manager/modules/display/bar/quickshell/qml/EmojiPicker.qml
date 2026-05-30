// Emoji picker. Fuzzy-search a Unicode emoji grid; selecting one types it
// into the focused window (wtype) and also copies it to the clipboard
// (wl-copy) as a fallback. Toggled with `qs ipc call emoji toggle`.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: picker

    property string query: ""
    property int selectedIndex: 0
    property var allEmoji: []

    readonly property int cardWidth: 560
    readonly property int cardHeight: 520
    readonly property int cellSize: 52

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
        if (picker.visible) picker.hide()
        else picker.show(window)
    }

    function show(window) {
        if (window && window.screen) picker.screen = window.screen
        picker.selectedIndex = 0
        input.text = ""
        picker.visible = true
        Qt.callLater(() => input.forceActiveFocus())
    }

    function hide() {
        picker.visible = false
    }

    function pick(index) {
        const items = picker.filtered
        const i = index !== undefined ? index : picker.selectedIndex
        if (i < 0 || i >= items.length) { picker.hide(); return }
        const ch = items[i].e
        picker.hide()
        // Copy as a fallback for apps that don't accept synthetic input…
        Quickshell.execDetached(["wl-copy", "--", ch])
        // …and type it into whatever regains focus after we close.
        typer.pending = ch
        typer.restart()
    }

    Timer {
        id: typer
        property string pending: ""
        interval: 120
        repeat: false
        onTriggered: {
            if (typer.pending.length > 0) {
                Quickshell.execDetached(["wtype", typer.pending])
                typer.pending = ""
            }
        }
    }

    Component.onCompleted: {
        const xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("emoji.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText) {
                try {
                    picker.allEmoji = JSON.parse(xhr.responseText)
                } catch (e) {
                    console.error("EmojiPicker: failed to parse emoji.json", e)
                }
            }
        }
        xhr.send()
    }

    readonly property var filtered: {
        const q = picker.query.toLowerCase().trim()
        if (q.length === 0) return picker.allEmoji
        const res = []
        for (let i = 0; i < picker.allEmoji.length; i++) {
            const it = picker.allEmoji[i]
            if (it.k.indexOf(q) >= 0) res.push(it)
        }
        return res
    }

    onFilteredChanged: picker.selectedIndex = 0

    readonly property int columns: Math.max(1, Math.floor(grid.width / picker.cellSize))

    // Backdrop dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: picker.hide()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: picker.cardWidth
        height: picker.cardHeight
        color: Theme.defaultBg
        radius: Theme.pillRadius
        border.color: Theme.activeBg
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: { /* eat */ }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Search field
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
                        placeholderText: "Search emoji…"
                        placeholderTextColor: Qt.darker(Theme.textColor, 1.6)
                        selectByMouse: true
                        onTextChanged: picker.query = text
                        focus: true

                        Keys.onPressed: function(event) {
                            const cols = picker.columns
                            const last = picker.filtered.length - 1
                            if (event.key === Qt.Key_Escape) {
                                picker.hide()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                picker.pick()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                picker.selectedIndex = Math.min(last, picker.selectedIndex + 1)
                                grid.positionViewAtIndex(picker.selectedIndex, GridView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left) {
                                picker.selectedIndex = Math.max(0, picker.selectedIndex - 1)
                                grid.positionViewAtIndex(picker.selectedIndex, GridView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down
                                    || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_J)) {
                                picker.selectedIndex = Math.min(last, picker.selectedIndex + cols)
                                grid.positionViewAtIndex(picker.selectedIndex, GridView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up
                                    || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_K)) {
                                picker.selectedIndex = Math.max(0, picker.selectedIndex - cols)
                                grid.positionViewAtIndex(picker.selectedIndex, GridView.Contain)
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            // Emoji grid
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: picker.cellSize
                cellHeight: picker.cellSize
                model: picker.filtered
                currentIndex: picker.selectedIndex

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: Theme.innerRadius
                        color: cell.index === picker.selectedIndex
                            ? Qt.lighter(Theme.defaultBg, 1.4)
                            : (cellHover.containsMouse
                                ? Qt.lighter(Theme.defaultBg, 1.2)
                                : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: Theme.fadeMs / 2 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cell.modelData ? cell.modelData.e : ""
                            font.pixelSize: 26
                        }

                        MouseArea {
                            id: cellHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: picker.selectedIndex = cell.index
                            onClicked: picker.pick(cell.index)
                        }
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }

            // Footer: name of the selected emoji + count
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    readonly property var sel: picker.filtered.length > picker.selectedIndex
                        ? picker.filtered[picker.selectedIndex]
                        : null
                    text: sel ? (sel.e + "  " + sel.n) : ""
                    color: Theme.textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight
                }

                Text {
                    text: picker.filtered.length + " emoji"
                    color: Qt.darker(Theme.textColor, 1.6)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 4
                }
            }
        }
    }

    IpcHandler {
        target: "emoji"

        function toggle() {
            picker.toggle(null)
        }

        function open() {
            picker.show(null)
        }

        function close() {
            picker.hide()
        }
    }
}
