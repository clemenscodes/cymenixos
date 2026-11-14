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

    // At most this many toasts on screen; the oldest make room (they stay in the history).
    readonly property int maxPopups: 5
    // History is capped too; the oldest notifications are dismissed.
    readonly property int maxHistory: 100

    // When each toast goes away (ms since epoch, 0 = stays until dismissed), keyed by
    // notification id. Kept here rather than in the toast: the toast list is rebuilt when it
    // changes, and per-toast timers restarted with every new notification, so with a steady
    // stream nothing ever expired and the stack grew off the screen.
    property var deadlines: ({})

    function toastDuration(n) {
        if (!n || n.urgency === NotificationUrgency.Critical) return 0
        // Apps asking for "never expire" (0, e.g. OBS) still get a normal toast; the
        // notification stays in the history.
        return n.expireTimeout > 0 ? n.expireTimeout : 5000
    }

    function pushPopup(n) {
        const d = root.toastDuration(n)
        root.deadlines[n.id] = d > 0 ? Date.now() + d : 0
        const arr = root.popups.concat([n])
        root.popups = arr.length > root.maxPopups ? arr.slice(arr.length - root.maxPopups) : arr
    }

    // Keeps a hovered toast up a little longer.
    function holdPopup(n) {
        if (n && root.deadlines[n.id] > 0)
            root.deadlines[n.id] = Math.max(root.deadlines[n.id], Date.now() + 1500)
    }

    readonly property Timer expiry: Timer {
        interval: 250
        repeat: true
        running: root.popups.length > 0
        onTriggered: {
            const now = Date.now()
            const keep = root.popups.filter(n => !(root.deadlines[n.id] > 0 && root.deadlines[n.id] <= now))
            if (keep.length !== root.popups.length) root.popups = keep
        }
    }

    function trimHistory() {
        if (!server.trackedNotifications) return
        const items = server.trackedNotifications.values.slice()
        for (let i = 0; i < items.length - root.maxHistory; i++) items[i].dismiss()
    }

    function removePopup(n) {
        if (n) delete root.deadlines[n.id]
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
            root.trimHistory()
        }
    }
}
