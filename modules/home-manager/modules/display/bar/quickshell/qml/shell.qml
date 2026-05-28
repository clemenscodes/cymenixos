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
        }
    }
}
