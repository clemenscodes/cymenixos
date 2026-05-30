pragma Singleton

// Native notification daemon. Owns org.freedesktop.Notifications via
// Quickshell's NotificationServer and replaces swaync entirely.
//
//   Notifs.list    — history (ObjectModel of tracked notifications)
//   Notifs.popups  — notifications currently shown as on-screen toasts
//   Notifs.dnd     — Do Not Disturb (suppresses toasts, still records history)
//
// NotificationPopups renders `popups`; NotificationCenter renders `list`.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false

    // Notifications currently shown as toasts. A plain JS array; reassign
    // (don't mutate) so Repeaters bound to it re-evaluate.
    property var popups: []

    readonly property var list: server.trackedNotifications
    readonly property int count: server.trackedNotifications
        ? server.trackedNotifications.values.length
        : 0

    function pushPopup(n) {
        root.popups = root.popups.concat([n])
    }

    function removePopup(n) {
        const arr = root.popups.slice()
        const i = arr.indexOf(n)
        if (i >= 0) {
            arr.splice(i, 1)
            root.popups = arr
        }
    }

    // Close a toast but keep it in the history list.
    function dropPopup(n) {
        root.removePopup(n)
    }

    // Dismiss entirely: removes from both toasts and history.
    function dismiss(n) {
        root.removePopup(n)
        if (n) n.dismiss()
    }

    function clearAll() {
        if (server.trackedNotifications) {
            const items = server.trackedNotifications.values.slice()
            for (let i = 0; i < items.length; i++) items[i].dismiss()
        }
        root.popups = []
    }

    function toggleDnd() {
        root.dnd = !root.dnd
        if (root.dnd) root.popups = []
    }

    NotificationServer {
        id: server

        // Clear everything when the shell reloads — history is ephemeral.
        keepOnReload: false

        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: function(notification) {
            // Retain it so it shows up in trackedNotifications (history).
            notification.tracked = true
            if (!root.dnd) root.pushPopup(notification)
        }
    }
}
