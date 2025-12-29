{lib, ...}: {config, ...}: let
  cfg = config.modules.editor;
in {
  config = lib.mkIf (cfg.enable && cfg.vscode.enable) {
    programs = {
      vscode = {
        profiles = {
          default = {
            enableExtensionUpdateCheck = false;
            enableUpdateCheck = false;
            userSettings = {
              "angular.forceStrictTemplates" = true;
              "chat.editor.fontFamily" = "VictorMono Nerd Font";
              "css.lint.unknownAtRules" = "ignore";
              "debug.terminal.clearBeforeReusing" = true;
              "debug.console.fontFamily" = "VictorMono Nerd Font";
              "editor.suggestSelection" = "first";
              "editor.scrollbar.horizontal" = "hidden";
              "editor.scrollbar.vertical" = "hidden";
              "editor.cursorBlinking" = "solid";
              "editor.defaultFormatter" = "biomejs.biome";
              "editor.fontFamily" = "VictorMono Nerd Font";
              "editor.linkedEditing" = true;
              "editor.fontSize" = 16;
              "editor.snippetSuggestions" = "top";
              "editor.inlineSuggest.fontFamily" = "VictorMono Nerd Font";
              "editor.inlayHints.fontFamily" = "VictorMono Nerd Font";
              "editor.codeLensFontFamily" = "VictorMono Nerd Font";
              "editor.inlayHints.enabled" = "off";
              "editor.defaultFoldingRangeProvider" = "biomejs.biome";
              "editor.minimap.enabled" = false;
              "editor.tokenColorCustomizations" = {
                "textMateRules" = [
                  {
                    "name" = "One Dark italic";
                    "scope" = [
                      "comment"
                      "entity.other.attribute-name"
                      "keyword"
                      "markup.underline.link"
                      "storage.modifier"
                      "storage.type"
                      "string.url"
                      "variable.language.super"
                      "variable.language.this"
                    ];
                    "settings" = {
                      "fontStyle" = "italic";
                    };
                  }
                  {
                    "name" = "One Dark italic reset";
                    "scope" = [
                      "keyword.operator"
                      "keyword.other.type"
                      "storage.modifier.import"
                      "storage.modifier.package"
                      "storage.type.built-in"
                      "storage.type.function.arrow"
                      "storage.type.generic"
                      "storage.type.java"
                      "storage.type.primitive"
                    ];
                    "settings" = {
                      "fontStyle" = "";
                    };
                  }
                ];
              };
              "eslint.format.enable" = false;
              "eslint.lintTask.options" = "";
              "explorer.confirmDelete" = false;
              "explorer.confirmDragAndDrop" = false;
              "extensions.experimental.affinity" = {
                "asvetliakov.vscode-neovim" = 1;
              };
              "extensions.ignoreRecommendations" = true;
              "files.autoSave" = "afterDelay";
              "files.autoSaveDelay" = 300;
              "files.eol" = "\n";
              "git.ignoreLimitWarning" = true;
              "git.ignoreMissingGitWarning" = true;
              "git.openRepositoryInParentFolders" = "never";
              "javascript.updateImportsOnFileMove.enabled" = "always";
              "jestrunner.codeLensSelector" = "**/*.{test,spec,it-spec,e2e-spec,e2e,it}.{js,jsx,ts,tsx}";
              "nixEnvSelector.suggestion" = false;
              "nixEnvSelector.useFlakes" = true;
              "redhat.telemetry.enabled" = false;
              "scm.inputFontFamily" = "Iosevka NF";
              "security.workspace.trust.untrustedFiles" = "open";
              "security.workspace.trust.banner" = "never";
              "terminal.integrated.scrollback" = 50000;
              "terminal.integrated.persistentSessionScrollback" = 10000;
              "terminal.integrated.allowMnemonics" = true;
              "terminal.integrated.copyOnSelection" = true;
              "terminal.external.linuxExec" = "kitty";
              "terminal.integrated.fontFamily" = "Iosevka NF";
              "terminal.integrated.macOptionIsMeta" = true;
              "terminal.integrated.cursorBlinking" = true;
              "terminal.explorerKind" = "external";
              "terminal.integrated.altClickMovesCursor" = false;
              "terminal.integrated.env.linux" = {};
              "terminal.integrated.smoothScrolling" = true;
              "terminal.integrated.shellIntegration.history" = 1000;
              "terminal.integrated.fontLigatures.enabled" = true;
              "terminal.integrated.enableMultiLinePasteWarning" = "never";
              "terminal.integrated.profiles.linux" = {
                zsh = {
                  path = "/bin/zsh";
                  args = ["-l" "-i"];
                };
              };
              "testing.resultsView.layout" = "treeLeft";
              "testing.alwaysRevealTestOnStateChange" = true;
              "testing.coverageToolbarEnabled" = true;
              "testing.followRunningTest" = true;
              "testing.showAllMessages" = true;
              "typescript.updateImportsOnFileMove.enabled" = "always";
              "vscode-neovim.logOutputToConsole" = true;
              "vscode-neovim.neovimClean" = true;
              "vscode-neovim.neovimInitVimPaths.linux" = "$HOME/.config/nvim/init.vscode.lua";
              "vscode-neovim.neovimExecutablePaths.linux" = "codevim";
              "vsicons.dontShowNewVersionMessage" = true;
              "vs-kubernetes" = {
                "vs-kubernetes.crd-code-completion" = "disabled";
              };
              "workbench.startupEditor" = "none";
              "workbench.iconTheme" = "vscode-icons";
              "workbench.colorTheme" = "One Dark Vivid";
              "whichkey.sortOrder" = "alphabetically";
              "whichkey.bindings" = [
                {
                  key = ";";
                  name = "commands";
                  type = "command";
                  command = "workbench.action.showCommands";
                }
                {
                  key = "/";
                  name = "comment";
                  type = "command";
                  command = "vscode-neovim.send";
                  args = "<C-/>";
                }
                {
                  key = "i";
                  name = "Format document";
                  type = "command";
                  command = "editor.action.formatDocument";
                }
                {
                  key = "o";
                  name = "Close other editors";
                  type = "command";
                  command = "workbench.action.closeOtherEditors";
                }
                {
                  key = "b";
                  name = "Buffers/Editors...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "b";
                      name = "Show all buffers/editors";
                      type = "command";
                      command = "workbench.action.showAllEditors";
                    }
                    {
                      key = "d";
                      name = "Close active editor";
                      type = "command";
                      command = "workbench.action.closeActiveEditor";
                    }
                    {
                      key = "h";
                      name = "Move editor into left group";
                      type = "command";
                      command = "workbench.action.moveEditorToLeftGroup";
                    }
                    {
                      key = "j";
                      name = "Move editor into below group";
                      type = "command";
                      command = "workbench.action.moveEditorToBelowGroup";
                    }
                    {
                      key = "k";
                      name = "Move editor into above group";
                      type = "command";
                      command = "workbench.action.moveEditorToAboveGroup";
                    }
                    {
                      key = "l";
                      name = "Move editor into right group";
                      type = "command";
                      command = "workbench.action.moveEditorToRightGroup";
                    }
                    {
                      key = "n";
                      name = "Next editor";
                      type = "command";
                      command = "workbench.action.nextEditor";
                    }
                    {
                      key = "p";
                      name = "Previous editor";
                      type = "command";
                      command = "workbench.action.previousEditor";
                    }
                    {
                      key = "N";
                      name = "New untitled editor";
                      type = "command";
                      command = "workbench.action.files.newUntitledFile";
                    }
                    {
                      key = "u";
                      name = "Reopen closed editor";
                      type = "command";
                      command = "workbench.action.reopenClosedEditor";
                    }
                    {
                      key = "y";
                      name = "Copy buffer to clipboard";
                      type = "commands";
                      commands = [
                        "editor.action.selectAll"
                        "editor.action.clipboardCopyAction"
                        "cancelSelection"
                      ];
                    }
                  ];
                }
                {
                  key = "d";
                  name = "Debug...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "d";
                      name = "Start debug";
                      type = "command";
                      command = "workbench.action.debug.start";
                    }
                    {
                      key = "S";
                      name = "Stop debug";
                      type = "command";
                      command = "workbench.action.debug.stop";
                    }
                    {
                      key = "c";
                      name = "Continue debug";
                      type = "command";
                      command = "workbench.action.debug.continue";
                    }
                    {
                      key = "p";
                      name = "Pause debug";
                      type = "command";
                      command = "workbench.action.debug.pause";
                    }
                    {
                      key = "r";
                      name = "Run without debugging";
                      type = "command";
                      command = "workbench.action.debug.run";
                    }
                    {
                      key = "R";
                      name = "Restart debug";
                      type = "command";
                      command = "workbench.action.debug.restart";
                    }
                    {
                      key = "i";
                      name = "Step into";
                      type = "command";
                      command = "workbench.action.debug.stepInto";
                    }
                    {
                      key = "s";
                      name = "Step over";
                      type = "command";
                      command = "workbench.action.debug.stepOver";
                    }
                    {
                      key = "o";
                      name = "Step out";
                      type = "command";
                      command = "workbench.action.debug.stepOut";
                    }
                    {
                      key = "b";
                      name = "Toggle breakpoint";
                      type = "command";
                      command = "editor.debug.action.toggleBreakpoint";
                    }
                    {
                      key = "B";
                      name = "Toggle inline breakpoint";
                      type = "command";
                      command = "editor.debug.action.toggleInlineBreakpoint";
                    }
                    {
                      key = "j";
                      name = "Jump to cursor";
                      type = "command";
                      command = "debug.jumpToCursor";
                    }
                    {
                      key = "v";
                      name = "REPL";
                      type = "command";
                      command = "workbench.debug.action.toggleRepl";
                    }
                    {
                      key = "w";
                      name = "Focus on watch window";
                      type = "command";
                      command = "workbench.debug.action.focusWatchView";
                    }
                    {
                      key = "W";
                      name = "Add to watch";
                      type = "command";
                      command = "editor.debug.action.selectionToWatch";
                    }
                  ];
                }
                {
                  key = "e";
                  name = "Toggle Explorer";
                  type = "command";
                  command = "workbench.action.toggleSidebarVisibility";
                }
                {
                  key = "s";
                  name = "Search & Replace...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "f";
                      name = "File";
                      type = "command";
                      command = "editor.action.startFindReplaceAction";
                    }
                    {
                      key = "s";
                      name = "Symbol";
                      type = "command";
                      command = "editor.action.rename";
                      when = "editorHasRenameProvider && editorTextFocus && !editorReadonly";
                    }
                    {
                      key = "p";
                      name = "Project";
                      type = "command";
                      command = "workbench.action.replaceInFiles";
                    }
                  ];
                }
                {
                  key = "g";
                  name = "Git...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "b";
                      name = "Checkout";
                      type = "command";
                      command = "git.checkout";
                    }
                    {
                      key = "c";
                      name = "Commit";
                      type = "command";
                      command = "git.commit";
                    }
                    {
                      key = "d";
                      name = "Delete Branch";
                      type = "command";
                      command = "git.deleteBranch";
                    }
                    {
                      key = "f";
                      name = "Fetch";
                      type = "command";
                      command = "git.fetch";
                    }
                    {
                      key = "i";
                      name = "Init";
                      type = "command";
                      command = "git.init";
                    }
                    {
                      key = "m";
                      name = "Merge";
                      type = "command";
                      command = "git.merge";
                    }
                    {
                      key = "p";
                      name = "Publish";
                      type = "command";
                      command = "git.publish";
                    }
                    {
                      key = "s";
                      name = "Stash";
                      type = "command";
                      command = "workbench.view.scm";
                    }
                    {
                      key = "S";
                      name = "Stage";
                      type = "command";
                      command = "git.stage";
                    }
                    {
                      key = "U";
                      name = "Unstage";
                      type = "command";
                      command = "git.unstage";
                    }
                  ];
                }
                {
                  key = "h";
                  name = "Split Horizontal";
                  type = "command";
                  command = "workbench.action.splitEditorDown";
                }
                {
                  key = "m";
                  name = "minimap";
                  type = "command";
                  command = "editor.action.toggleMinimap";
                }
                {
                  key = "n";
                  name = "highlight";
                  type = "command";
                  command = "vscode-neovim.send";
                  args = ":noh<CR>";
                }
                {
                  key = "f";
                  name = "Search...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "f";
                      name = "files";
                      type = "command";
                      command = "workbench.action.quickOpen";
                    }
                    {
                      key = "g";
                      name = "text";
                      type = "command";
                      command = "workbench.action.findInFiles";
                    }
                  ];
                }
                {
                  key = "S";
                  name = "Show...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "e";
                      name = "Show explorer";
                      type = "command";
                      command = "workbench.view.explorer";
                    }
                    {
                      key = "s";
                      name = "Show search";
                      type = "command";
                      command = "workbench.view.search";
                    }
                    {
                      key = "g";
                      name = "Show source control";
                      type = "command";
                      command = "workbench.view.scm";
                    }
                    {
                      key = "t";
                      name = "Show test";
                      type = "command";
                      command = "workbench.view.extension.test";
                    }
                    {
                      key = "r";
                      name = "Show remote explorer";
                      type = "command";
                      command = "workbench.view.remote";
                    }
                    {
                      key = "x";
                      name = "Show extensions";
                      type = "command";
                      command = "workbench.view.extensions";
                    }
                    {
                      key = "p";
                      name = "Show problem";
                      type = "command";
                      command = "workbench.actions.view.problems";
                    }
                    {
                      key = "o";
                      name = "Show output";
                      type = "command";
                      command = "workbench.action.output.toggleOutput";
                    }
                    {
                      key = "d";
                      name = "Show debug console";
                      type = "command";
                      command = "workbench.debug.action.toggleRepl";
                    }
                  ];
                }
                {
                  key = "t";
                  name = "Terminal...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "t";
                      name = "Toggle Terminal";
                      type = "command";
                      command = "workbench.action.togglePanel";
                    }
                  ];
                }
                {
                  key = "T";
                  name = "UI toggles...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "b";
                      name = "Toggle side bar visibility";
                      type = "command";
                      command = "workbench.action.toggleSidebarVisibility";
                    }
                    {
                      key = "j";
                      name = "Toggle panel visibility";
                      type = "command";
                      command = "workbench.action.togglePanel";
                    }
                    {
                      key = "F";
                      name = "Toggle full screen";
                      type = "command";
                      command = "workbench.action.toggleFullScreen";
                    }
                    {
                      key = "s";
                      name = "Select theme";
                      type = "command";
                      command = "workbench.action.selectTheme";
                    }
                    {
                      key = "m";
                      name = "Toggle maximized panel";
                      type = "command";
                      command = "workbench.action.toggleMaximizedPanel";
                    }
                    {
                      key = "t";
                      name = "Toggle tool/activity bar visibility";
                      type = "command";
                      command = "workbench.action.toggleActivityBarVisibility";
                    }
                    {
                      key = "T";
                      name = "Toggle tab visibility";
                      type = "command";
                      command = "workbench.action.toggleTabsVisibility";
                    }
                  ];
                }
                {
                  key = "v";
                  name = "Split Vertical";
                  type = "command";
                  command = "workbench.action.splitEditor";
                }
                {
                  key = "w";
                  name = "Window...";
                  type = "bindings";
                  bindings = [
                    {
                      key = "W";
                      name = "Focus previous editor group";
                      type = "command";
                      command = "workbench.action.focusPreviousGroup";
                    }
                    {
                      key = "h";
                      name = "Move editor group left";
                      type = "command";
                      command = "workbench.action.moveActiveEditorGroupLeft";
                    }
                    {
                      key = "j";
                      name = "Move editor group down";
                      type = "command";
                      command = "workbench.action.moveActiveEditorGroupDown";
                    }
                    {
                      key = "k";
                      name = "Move editor group up";
                      type = "command";
                      command = "workbench.action.moveActiveEditorGroupUp";
                    }
                    {
                      key = "l";
                      name = "Move editor group right";
                      type = "command";
                      command = "workbench.action.moveActiveEditorGroupRight";
                    }
                    {
                      key = "t";
                      name = "Toggle editor group sizes";
                      type = "command";
                      command = "workbench.action.toggleEditorWidths";
                    }
                    {
                      key = "m";
                      name = "Maximize editor group";
                      type = "command";
                      command = "workbench.action.minimizeOtherEditors";
                    }
                    {
                      key = "M";
                      name = "Maximize editor group and hide side bar";
                      type = "command";
                      command = "workbench.action.maximizeEditor";
                    }
                    {
                      key = "=";
                      name = "Reset editor group sizes";
                      type = "command";
                      command = "workbench.action.evenEditorWidths";
                    }
                    {
                      key = "z";
                      name = "Combine all editors";
                      type = "command";
                      command = "workbench.action.joinAllGroups";
                    }
                    {
                      key = "d";
                      name = "Close editor group";
                      type = "command";
                      command = "workbench.action.closeEditorsInGroup";
                    }
                    {
                      key = "x";
                      name = "Close all editor groups";
                      type = "command";
                      command = "workbench.action.closeAllGroups";
                    }
                  ];
                }
                {
                  key = "z";
                  name = "Toggle zen mode";
                  type = "command";
                  command = "workbench.action.toggleZenMode";
                }
              ];
            };
          };
        };
      };
    };
  };
}
