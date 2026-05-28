//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        TopBar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        BottomBar {
            required property var modelData
            screen: modelData
        }
    }
}
