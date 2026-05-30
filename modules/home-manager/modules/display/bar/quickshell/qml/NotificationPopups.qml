// On-screen toast stack for incoming notifications. Renders Notifs.popups
// in the top-right corner. Each toast auto-dismisses after its timeout
// (paused while hovered); critical notifications stay until dismissed.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

PanelWindow {
    id: popups

    anchors {
        top: true
        right: true
    }

    readonly property int toastWidth: 400

    implicitWidth: toastWidth + 24
    implicitHeight: Math.max(1, column.implicitHeight + 16)

    color: "transparent"
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    visible: Notifs.popups.length > 0

    Column {
        id: column
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 12
        width: popups.toastWidth
        spacing: 8

        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: Theme.fadeMs
            }
            NumberAnimation {
                property: "x"
                from: popups.toastWidth
                to: 0
                duration: Theme.fadeMs
                easing.type: Easing.OutCubic
            }
        }
        move: Transition {
            NumberAnimation { properties: "x,y"; duration: Theme.fadeMs; easing.type: Easing.OutCubic }
        }

        Repeater {
            model: Notifs.popups

            delegate: Rectangle {
                id: toast
                required property var modelData

                readonly property bool critical:
                    modelData && modelData.urgency === NotificationUrgency.Critical
                readonly property int duration: {
                    if (toast.critical) return 0
                    if (!modelData) return 5000
                    if (modelData.expireTimeout === 0) return 0
                    if (modelData.expireTimeout > 0) return modelData.expireTimeout
                    return 5000
                }

                width: parent.width
                implicitHeight: layout.implicitHeight + 24
                radius: Theme.pillRadius
                color: Theme.defaultBg
                border.width: 1
                border.color: toast.critical ? Theme.urgentBg : Theme.activeBg

                // Drop the toast (keep in history) when it is closed from
                // anywhere else (app withdrew it, dismissed in the center…).
                Connections {
                    target: toast.modelData
                    function onClosed() { Notifs.removePopup(toast.modelData) }
                }

                Timer {
                    running: toast.duration > 0 && !hoverArea.containsMouse
                    interval: toast.duration
                    repeat: false
                    onTriggered: Notifs.dropPopup(toast.modelData)
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    // Left-click the body invokes the default action if any,
                    // otherwise just dismisses the toast.
                    onClicked: {
                        const acts = toast.modelData ? toast.modelData.actions : []
                        const def = acts ? acts.find(a => a.identifier === "default") : null
                        if (def) {
                            def.invoke()
                            Notifs.dismiss(toast.modelData)
                        } else {
                            Notifs.dropPopup(toast.modelData)
                        }
                    }
                }

                Column {
                    id: layout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 6

                    // Header: app icon + name + close button
                    Item {
                        width: parent.width
                        height: 20

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 16
                                readonly property string iconSource: {
                                    const n = toast.modelData
                                    if (!n || !n.appIcon) return ""
                                    return Quickshell.iconPath(n.appIcon, true)
                                }
                                visible: iconSource.length > 0
                                source: iconSource
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: toast.modelData ? (toast.modelData.appName || "Notification") : ""
                                color: Qt.darker(Theme.textColor, 1.4)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 4
                                font.bold: true
                            }
                        }

                        Rectangle {
                            id: closeBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 9
                            color: closeHover.containsMouse ? Theme.urgentBg : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: Theme.fadeMs / 2 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: Theme.textColor
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 6
                            }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.dismiss(toast.modelData)
                            }
                        }
                    }

                    // Body: text + optional image
                    Row {
                        width: parent.width
                        spacing: 10

                        Column {
                            width: bodyImage.visible ? parent.width - bodyImage.width - 10 : parent.width
                            spacing: 3

                            Text {
                                width: parent.width
                                visible: text.length > 0
                                text: toast.modelData ? (toast.modelData.summary || "") : ""
                                color: Theme.textColor
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                font.bold: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                visible: text.length > 0
                                text: toast.modelData ? (toast.modelData.body || "") : ""
                                color: Qt.darker(Theme.textColor, 1.2)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 3
                                textFormat: Text.StyledText
                                wrapMode: Text.WordWrap
                                maximumLineCount: 6
                                elide: Text.ElideRight
                                onLinkActivated: (link) => Quickshell.execDetached(["xdg-open", link])
                            }
                        }

                        IconImage {
                            id: bodyImage
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 48
                            readonly property string imageSource:
                                toast.modelData ? (toast.modelData.image || "") : ""
                            visible: imageSource.length > 0
                            source: imageSource
                        }
                    }

                    // Actions
                    Flow {
                        width: parent.width
                        spacing: 6
                        visible: toast.modelData
                            && toast.modelData.actions
                            && toast.modelData.actions.length > 0

                        Repeater {
                            model: toast.modelData ? toast.modelData.actions : []

                            delegate: Rectangle {
                                id: actBtn
                                required property var modelData

                                visible: actBtn.modelData.identifier !== "default"
                                implicitWidth: actLabel.implicitWidth + 20
                                implicitHeight: 26
                                radius: Theme.innerRadius
                                color: actHover.containsMouse
                                    ? Qt.lighter(Theme.defaultBg, 1.4)
                                    : Qt.lighter(Theme.defaultBg, 1.2)

                                Behavior on color {
                                    ColorAnimation { duration: Theme.fadeMs / 2 }
                                }

                                Text {
                                    id: actLabel
                                    anchors.centerIn: parent
                                    text: actBtn.modelData.text || actBtn.modelData.identifier
                                    color: Theme.textColor
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 4
                                }

                                MouseArea {
                                    id: actHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        actBtn.modelData.invoke()
                                        Notifs.dismiss(toast.modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
