//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import Quickshell

ShellRoot {
    AppLauncher {
        id: appLauncher
    }

    PowerMenu {
        id: powerMenu
    }

    Variants {
        model: Quickshell.screens

        TopBar {
            required property var modelData
            screen: modelData
            powerMenu: powerMenu
        }
    }

    Variants {
        model: Quickshell.screens

        BottomBar {
            required property var modelData
            screen: modelData
            appLauncher: appLauncher
        }
    }
}
