//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import Quickshell

ShellRoot {
    AppLauncher {
        id: shellAppLauncher
    }

    PowerMenu {
        id: shellPowerMenu
    }

    BluetoothMenu {
        id: shellBluetoothMenu
    }

    NotificationCenter {
        id: shellNotifCenter
    }

    // Owns org.freedesktop.Notifications and renders incoming toasts.
    NotificationPopups {}

    EmojiPicker {
        id: shellEmojiPicker
    }

    Variants {
        model: Quickshell.screens

        TopBar {
            required property var modelData
            screen: modelData
            powerMenu: shellPowerMenu
        }
    }

    Variants {
        model: Quickshell.screens

        BottomBar {
            required property var modelData
            screen: modelData
            appLauncher: shellAppLauncher
            bluetoothMenu: shellBluetoothMenu
            notifCenter: shellNotifCenter
        }
    }
}
