{
  inputs,
  pkgs,
  lib,
  ...
}: {
  system,
  config,
  ...
}: let
  cfg = config.modules.development;
in {
  options = {
    modules = {
      development = {
        tongo = {
          enable = lib.mkEnableOption "Enable tongo support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.tongo.enable) {
    home = {
      packages = [pkgs.tongo];
    };
    xdg = {
      configFile = {
        "tongo/theme.toml" = {
          text = ''
            # A color theme for `tongo` (https://github.com/drewzemke/tongo)
            # Inspired by the "Catppuccin Mocha" color theme (https://github.com/catppuccin/catppuccin)

            # To use this theme in `tongo`, move (or link) it to `~/.config/tongo/theme.toml` on Mac/Linux and `<your-user-folder>\AppData\Roaming\tongo\theme.toml` on Windows.

            [palette]
            rosewater = "#f5e0dc"
            flamingo = "#f2cdcd"
            pink = "#f5c2e7"
            mauve = "#cba6f7"
            red = "#f38ba8"
            maroon = "#eba0ac"
            peach = "#fab387"
            yellow = "#f9e2af"
            green = "#a6e3a1"
            teal = "#94e2d5"
            sky = "#89dceb"
            sapphire = "#74c7ec"
            blue = "#89b4fa"
            lavender = "#b4befe"
            text = "#cdd6f4"
            subtext1 = "#bac2de"
            subtext0 = "#a6adc8"
            overlay2 = "#9399b2"
            overlay1 = "#7f849c"
            overlay0 = "#6c7086"
            surface2 = "#585b70"
            surface1 = "#45475a"
            surface0 = "#313244"
            base = "#1e1e2e"
            mantle = "#181825"
            crust = "#11111b"

            [ui]
            fg-primary = "text"
            fg-secondary = "lavender"
            selection-bg = "mauve"
            selection-fg = "base"
            indicator-success = "green"
            indicator-error = "red"
            indicator-info = "blue"
            app-name = "pink"

            [panel]
            active-bg = "base"
            active-border = "sapphire"
            inactive-bg = "crust"
            inactive-border = "surface1"
            active-input-border = "teal"

            [popup]
            border = "flamingo"
            bg = "base"

            [tab]
            active = "peach"
            inactive = "overlay1"

            [data]
            boolean = "yellow"
            date = "sky"
            key = "flamingo"
            number = "pink"
            object-id = "sapphire"
            string = "green"
            punctuation = "mauve"
            mongo-operator = "teal"

            [documents]
            note = "rosewater"
            search = "blue"
          '';
        };
        "tongo/config.toml" = {
          text = ''
            # NOTE: the available commands are subject to change between major (meaning 0.x)
            # releases. If this config can't be loaded because of an incompatibility, move
            # it to a backup location and restart `tongo` to generate a new config.

            # NOTE: the values shown for each configuration are the defaults. Uncomment them
            # to customize to your liking. You can use "C-" and "A-" to create keybindings
            # that use the control and alt/option keys, eg. "C-w" or "A-enter".

            # How many documents are loaded in the documents view at a time
            # page-size = 5

            [keys]
            # Moves the selection cursor around lists and the documents view
            nav-up = "k"
            nav-down = "j"
            nav-left = "h"
            nav-right = "l"

            # Changes the currently focused panel
            # focus-up = "K"
            # focus-down = "J"
            # focus-left = "H"
            # focus-right = "L"

            # Selects things in lists, says "yes" to confirmations, or navigates forward
            # confirm = "enter"

            # Says "no" to confirmations or navigates backwards
            # back = "esc"

            # Starts creating a new connection, database, collection, or document
            # create-new = "A"

            # Starts editing the currently-selected connection or document
            # edit = "E"

            # Deletes (or drops) the currently-selected connection, database, collection, or document
            # delete = "D"

            # Resets the value of a search field
            # reset = "R"

            # Refreshes the documents view with updated data
            # refresh = "r"

            # Expands or collapses tree items in the documents view
            # expand-collapse = "space"

            # Navigates between pages of documents in the documents view
            # next-page = "n"
            # previous-page = "p"
            # first-page = "P"
            # last-page = "N"

            # Starts a fuzzy search of the documents on the current page
            # search = "/"

            # Duplicates a document, opening an editor to make changes before saving
            # duplicate-doc = "C"

            # Copies the currently-selected document (or sub-document) to the system clipbard
            # yank = "y"

            # Creates a new blank tab
            # new-tab = "T"

            # Creates a new tab that is identical to (but independent from) the current one
            # duplicate-tab = "S"

            # Closes the current tab. This can't be undone!
            # close-tab = "X"

            # Navigates between tabs
            # next-tab = "]"
            # previous-tab = "["
            # goto-tab-1 = "1"
            # goto-tab-2 = "2"
            # goto-tab-3 = "3"
            # goto-tab-4 = "4"
            # goto-tab-5 = "5"
            # goto-tab-6 = "6"
            # goto-tab-7 = "7"
            # goto-tab-8 = "8"
            # goto-tab-9 = "9"

            # Opens an interactive view of all the currently-available commands
            # show-commands = "?"

            # Closes tongo. Come back soon!
            # quit = "q"
          '';
        };
      };
    };
  };
}
