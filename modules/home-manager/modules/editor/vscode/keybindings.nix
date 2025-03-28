{lib, ...}: {config, ...}: let
  cfg = config.modules.editor;
in {
  config = lib.mkIf (cfg.enable && cfg.vscode.enable) {
    programs = {
      vscode = {
        keybindings = [
          {
            key = "ctrl+g";
            command = "vscode-neovim.send";
            when = "editorTextFocus && neovim.init";
            args = "<C-/>";
          }
          {
            key = "shift+ctrl+e";
            command = "actions.findWithSelection";
          }
          {
            key = "ctrl+e";
            command = "-actions.findWithSelection";
          }
          {
            key = "ctrl+e";
            command = "workbench.view.explorer";
          }
          {
            key = "shift+ctrl+e";
            command = "-workbench.view.explorer";
          }
          {
            key = "r";
            command = "renameFile";
            when = "explorerViewletVisible && filesExplorerFocus && !explorerResourceIsRoot && !explorerResourceReadonly && !inputFocus";
          }
          {
            key = "enter";
            command = "-renameFile";
            when = "explorerViewletVisible && filesExplorerFocus && !explorerResourceIsRoot && !explorerResourceReadonly && !inputFocus";
          }
          {
            key = "j";
            command = "list.focusDown";
            when = "listFocus && explorerViewletVisible && filesExplorerFocus && !explorerResourceIsRoot && !explorerResourceReadonly && !inputFocus";
          }
          {
            key = "k";
            command = "list.focusUp";
            when = "listFocus && explorerViewletVisible && filesExplorerFocus && !explorerResourceIsRoot && !explorerResourceReadonly && !inputFocus";
          }
          {
            key = "ctrl+j";
            command = "selectNextSuggestion";
            when = "editorTextFocus && suggestWidgetMultipleSuggestions && suggestWidgetVisible";
          }
          {
            key = "ctrl+k";
            command = "selectPrevSuggestion";
            when = "editorTextFocus && suggestWidgetMultipleSuggestions && suggestWidgetVisible";
          }
          {
            key = "ctrl+j";
            command = "workbench.action.quickOpenNavigateNext";
            when = "inQuickOpen";
          }
          {
            key = "tab";
            command = "selectNextSuggestion";
            when = "editorTextFocus && suggestWidgetMultipleSuggestions && suggestWidgetVisible";
          }
          {
            key = "tab";
            command = "workbench.action.quickOpenNavigateNext";
            when = "inQuickOpen";
          }
          {
            key = "shit+tab";
            command = "selectPrevSuggestion";
            when = "editorTextFocus && suggestWidgetMultipleSuggestions && suggestWidgetVisible";
          }
          {
            key = "shift+tab";
            command = "selectPrevSuggestion";
            when = "editorTextFocus && suggestWidgetMultipleSuggestions && suggestWidgetVisible";
          }
          {
            key = "shift+tab";
            command = "workbench.action.quickOpenNavigatePrevious";
            when = "inQuickOpen";
          }
          {
            key = "ctrl+k";
            command = "workbench.action.quickOpenNavigatePrevious";
            when = "inQuickOpen";
          }
          {
            key = "enter";
            command = "list.select";
            when = "explorerViewletVisible && filesExplorerFocus";
          }
          {
            key = "l";
            command = "list.select";
            when = "explorerViewletVisible && filesExplorerFocus && !inputFocus";
          }
          {
            key = "o";
            command = "list.toggleExpand";
            when = "explorerViewletVisible && filesExplorerFocus && !inputFocus";
          }
          {
            key = "h";
            command = "list.collapse";
            when = "explorerViewletVisible && filesExplorerFocus && !inputFocus";
          }
          {
            key = "a";
            command = "explorer.newFile";
            when = "filesExplorerFocus && !inputFocus";
          }
          {
            key = "shift+a";
            command = "explorer.newFolder";
            when = "filesExplorerFocus && !inputFocus";
          }
          {
            key = "shift+;";
            command = "insertPrevSuggestion";
            when = "hasOtherSuggestions && textInputFocus && textInputFocus && !inSnippetMode && !suggestWidgetVisible && config.editor.tabCompletion == 'on'";
          }
          {
            key = "ctrl+j";
            when = "editorTextFocus";
            command = "workbench.action.navigateDown";
          }
          {
            key = "ctrl+k";
            when = "editorTextFocus";
            command = "workbench.action.navigateUp";
          }
          {
            key = "ctrl+h";
            when = "editorTextFocus";
            command = "workbench.action.navigateLeft";
          }
          {
            key = "ctrl+l";
            when = "editorTextFocus";
            command = "workbench.action.navigateRight";
          }
          {
            key = "space";
            when = "editorTextFocus && neovim.mode == 'normal'";
            command = "whichkey.show";
          }
          {
            key = "ctrl+l";
            when = "sideBarFocus";
            command = "workbench.action.focusActiveEditorGroup";
          }
          {
            key = "ctrl+k";
            command = "workbench.action.focusActiveEditorGroup";
            when = "terminalFocus";
          }
          {
            key = "ctrl+shift+t";
            command = "workbench.action.terminal.focus";
            when = "!terminalFocus";
          }
          {
            key = "ctrl+j";
            command = "-editor.action.insertLineAfter";
            when = "editorTextFocus && neovim.ctrlKeysInsert && !neovim.recording && neovim.mode == 'insert'";
          }
          {
            key = "alt+j";
            command = "workbench.action.terminal.focus";
            when = "!terminalFocus";
          }
          {
            key = "ctrl+shift+t";
            command = "workbench.action.togglePanel";
          }
          {
            key = "ctrl+j";
            command = "-workbench.action.togglePanel";
          }
          {
            key = "ctrl+k ctrl+i";
            command = "-editor.action.showHover";
            when = "editorTextFocus";
          }
          {
            key = "shift+tab";
            command = "-acceptAlternativeSelectedSuggestion";
            when = "suggestWidgetVisible && textInputFocus && textInputFocus";
          }
          {
            key = "ctrl+f";
            command = "-vscode-neovim.ctrl-f";
            when = "editorTextFocus && neovim.ctrlKeysNormal && neovim.init && neovim.mode != 'insert'";
          }
        ];
      };
    };
  };
}
