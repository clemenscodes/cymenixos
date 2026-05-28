//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QT_STYLE_OVERRIDE=Fusion
//@ pragma Env QT_QPA_PLATFORMTHEME=

import QtQuick
import Quickshell

ShellRoot {
    // Make Qt's platform menus (QMenu used by QsMenuAnchor) pick up the
    // bar's purple/pink theme. Fusion respects the application palette,
    // so we override it here. Qt.application.font is also pushed onto
    // the Iosevka Nerd Font Mono.
    Component.onCompleted: {
        const p = Qt.application.palette
        if (p) {
            p.window = Theme.defaultBg
            p.windowText = Theme.textColor
            p.base = Theme.defaultBg
            p.alternateBase = Qt.lighter(Theme.defaultBg, 1.2)
            p.text = Theme.textColor
            p.button = Theme.defaultBg
            p.buttonText = Theme.textColor
            p.highlight = Theme.activeBg
            p.highlightedText = Theme.activeTextColor
            p.link = Theme.activeBg
            p.midlight = Qt.lighter(Theme.defaultBg, 1.4)
            p.shadow = Qt.darker(Theme.defaultBg, 1.6)
            p.tooltipBase = Theme.defaultBg
            p.tooltipText = Theme.textColor
        }
        const f = Qt.application.font
        if (f) {
            f.family = Theme.fontFamily
            f.pixelSize = Theme.fontSize - 2
        }
    }

    AppLauncher {
        id: shellAppLauncher
    }

    PowerMenu {
        id: shellPowerMenu
    }

    BluetoothMenu {
        id: shellBluetoothMenu
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
        }
    }
}
