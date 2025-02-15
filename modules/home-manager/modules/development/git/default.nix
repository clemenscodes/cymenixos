{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.development;
in {
  options = {
    modules = {
      development = {
        git = {
          enable = lib.mkEnableOption "Enable Git" // {default = false;};
          userName = lib.mkOption {
            type = lib.types.str;
            default = null;
          };
          userEmail = lib.mkOption {
            type = lib.types.str;
            default = null;
          };
          gpgFingerprint = lib.mkOption {
            type = lib.types.str;
            default = null;
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.git.enable) {
    home = {
      packages = [pkgs.gitflow];
    };
    programs = {
      lazygit = {
        inherit (cfg.git) enable;
        settings = {
          gui = {
            scrollHeight = 2;
            scrollPastBottom = true;
            scrollOffMargin = 2;
            scrollOffBehavior = "margin";
            mouseEvents = true;
            skipDiscardChangeWarning = false;
            skipStashWarning = false;
            skipNoStagedFilesWarning = false;
            skipRewordInEditorWarning = false;
            sidePanelWidth = 0.3333;
            expandFocusedSidePanel = false;
            expandedSidePanelWeight = 2;
            mainPanelSplitMode = "flexible";
            enlargedSideViewLocation = "left";
            wrapLinesInStagingView = true;
            language = "auto";
            timeFormat = "02 Jan 06";
            shortTimeFormat = "3:04PM";
            theme = {
              activeBorderColor = ["green" "bold"];
              inactiveBorderColor = ["default"];
              searchingActiveBorderColor = ["cyan" "bold"];
              optionsTextColor = ["blue"];
              selectedLineBgColor = ["blue"];
              inactiveViewSelectedLineBgColor = ["bold"];
              cherryPickedCommitFgColor = ["blue"];
              cherryPickedCommitBgColor = ["cyan"];
              markedBaseCommitFgColor = ["blue"];
              markedBaseCommitBgColor = ["yellow"];
              unstagedChangesColor = ["red"];
              defaultFgColor = ["default"];
            };
            commitLength = {
              show = true;
            };
            showListFooter = true;
            showFileTree = true;
            showNumstatInFilesView = false;
            showRandomTip = true;
            showCommandLog = true;
            showBottomLine = true;
            showPanelJumps = true;
            showIcons = false;
            nerdFontsVersion = "";
            showFileIcons = true;
            commitAuthorShortLength = 2;
            commitAuthorLongLength = 17;
            commitHashLength = 8;
            showBranchCommitHash = false;
            showDivergenceFromBaseBranch = "none";
            commandLogSize = 8;
            splitDiff = "auto";
            screenMode = "normal";
            border = "rounded";
            animateExplosion = true;
            portraitMode = "auto";
            filterMode = "substring";
            spinner = {
              frames = ["|" "/" "-" "\\"];
              rate = 50;
            };
            statusPanelView = "dashboard";
            switchToFilesAfterStashPop = true;
            switchToFilesAfterStashApply = true;
            switchTabsWithPanelJumpKeys = false;
          };
          git = {
            paging = {
              colorArg = "always";
              pager = "";
              useConfig = false;
              externalDiffCommand = "${pkgs.difftastic}/bin/difft --color=always";
            };
            commit = {
              signOff = false;
              autoWrapCommitMessage = true;
              autoWrapWidth = 72;
            };
            merging = {
              manualCommit = false;
              args = "";
              squashMergeMessage = "Squash merge {{selectedRef}} into {{currentBranch}}";
            };
            mainBranches = ["master" "main"];
            skipHookPrefix = "WIP";
            autoFetch = true;
            autoRefresh = true;
            fetchAll = true;
            autoStageResolvedConflicts = true;
            branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
            allBranchesLogCmd = "git log --graph --all --color=always --abbrev-commit --decorate --date=relative  --pretty=medium";
            overrideGpg = false;
            disableForcePushing = false;
            commitPrefix = {
              pattern = "";
              replace = "";
            };
            branchPrefix = "";
            parseEmoji = false;
            log = {
              order = "topo-order";
              showGraph = "always";
              showWholeGraph = false;
            };
            truncateCopiedCommitHashesTo = 12;
          };

          update = {
            method = "prompt";
            days = 14;
          };

          refresher = {
            refreshInterval = 10;
            fetchInterval = 60;
          };

          confirmOnQuit = false;
          quitOnTopLevelReturn = false;

          os = {
            edit = "";
            editAtLine = "";
            editAtLineAndWait = "";
            openDirInEditor = "";
            editPreset = "";
            open = "";
            openLink = "";
            editCommand = "";
            editCommandTemplate = "";
            openCommand = "";
            openLinkCommand = "";
            copyToClipboardCmd = "";
            readFromClipboardCmd = "";
          };

          disableStartupPopups = true;
          notARepository = "prompt";
          promptToReturnFromSubprocess = true;

          keybinding = {
            universal = {
              quit = "q";
              quitAlt1 = "<c-c>";
              return = "<esc>";
              quitWithoutChangingDirectory = "Q";
              togglePanel = "<tab>";
              prevItem = "<up>";
              nextItem = "<down>";
              prevItemAlt = "k";
              nextItemAlt = "j";
              prevPage = ",";
              nextPage = ".";
              scrollLeft = "H";
              scrollRight = "L";
              gotoTop = "<";
              gotoBottom = ">";
              toggleRangeSelect = "v";
              rangeSelectDown = "<s-down>";
              rangeSelectUp = "<s-up>";
              prevBlock = "<left>";
              nextBlock = "<right>";
              prevBlockAlt = "h";
              nextBlockAlt = "l";
              nextBlockAlt2 = "<tab>";
              prevBlockAlt2 = "<backtab>";
              jumpToBlock = ["1" "2" "3" "4" "5"];
              nextMatch = "n";
              prevMatch = "N";
              startSearch = "/";
              optionMenu = "<disabled>";
              optionMenuAlt1 = "?";
              select = "<space>";
              goInto = "<enter>";
              confirm = "<enter>";
              confirmInEditor = "<a-enter>";
              remove = "d";
              new = "n";
              edit = "e";
              openFile = "o";
              scrollUpMain = "<pgup>";
              scrollDownMain = "<pgdown>";
              scrollUpMainAlt1 = "K";
              scrollDownMainAlt1 = "J";
              scrollUpMainAlt2 = "<c-u>";
              scrollDownMainAlt2 = "<c-d>";
              executeShellCommand = ":";
              createRebaseOptionsMenu = "m";
              pushFiles = "P";
              pullFiles = "p";
              refresh = "R";
              createPatchOptionsMenu = "<c-p>";
              nextTab = "]";
              prevTab = "[";
              nextScreenMode = "+";
              prevScreenMode = "_";
              undo = "z";
              redo = "<c-z>";
              filteringMenu = "<c-s>";
              diffingMenu = "W";
              diffingMenuAlt = "<c-e>";
              copyToClipboard = "<c-o>";
              openRecentRepos = "<c-r>";
              submitEditorText = "<enter>";
              extrasMenu = "@";
              toggleWhitespaceInDiffView = "<c-w>";
              increaseContextInDiffView = "}";
              decreaseContextInDiffView = "{";
              increaseRenameSimilarityThreshold = ")";
              decreaseRenameSimilarityThreshold = "(";
              openDiffTool = "<c-t>";
            };
            status = {
              checkForUpdate = "u";
              recentRepos = "<enter>";
              allBranchesLogGraph = "a";
            };
            files = {
              commitChanges = "c";
              commitChangesWithoutHook = "w";
              amendLastCommit = "A";
              commitChangesWithEditor = "C";
              findBaseCommitForFixup = "<c-f>";
              confirmDiscard = "x";
              ignoreFile = "i";
              refreshFiles = "r";
              stashAllChanges = "s";
              viewStashOptions = "S";
              toggleStagedAll = "a";
              viewResetOptions = "D";
              fetch = "f";
              toggleTreeView = "`";
              openMergeTool = "M";
              openStatusFilter = "<c-b>";
              copyFileInfoToClipboard = "y";
              collapseAll = "-";
              expandAll = "=";
            };
            branches = {
              createPullRequest = "o";
              viewPullRequestOptions = "O";
              copyPullRequestURL = "<c-y>";
              checkoutBranchByName = "c";
              forceCheckoutBranch = "F";
              rebaseBranch = "r";
              renameBranch = "R";
              mergeIntoCurrentBranch = "M";
              viewGitFlowOptions = "i";
              fastForward = "f";
              createTag = "T";
              pushTag = "P";
              setUpstream = "u";
              fetchRemote = "f";
              sortOrder = "s";
            };
            worktrees = {
              viewWorktreeOptions = "w";
            };
            commits = {
              squashDown = "s";
              renameCommit = "r";
              renameCommitWithEditor = "R";
              viewResetOptions = "g";
              markCommitAsFixup = "f";
              createFixupCommit = "F";
              squashAboveCommits = "S";
              moveDownCommit = "<c-j>";
              moveUpCommit = "<c-k>";
              amendToCommit = "A";
              resetCommitAuthor = "a";
              pickCommit = "p";
              revertCommit = "t";
              cherryPickCopy = "C";
              pasteCommits = "V";
              markCommitAsBaseForRebase = "B";
              tagCommit = "T";
              checkoutCommit = "<space>";
              resetCherryPick = "<c-R>";
              copyCommitAttributeToClipboard = "y";
              openLogMenu = "<c-l>";
              openInBrowser = "o";
              viewBisectOptions = "b";
              startInteractiveRebase = "i";
            };
          };
        };
      };
      gitui = {
        inherit (cfg.git) enable;
        keyConfig = ''
          open_help: Some(( code: F(1), modifiers: "")),

          move_left: Some(( code: Char('h'), modifiers: "")),
          move_right: Some(( code: Char('l'), modifiers: "")),
          move_up: Some(( code: Char('k'), modifiers: "")),
          move_down: Some(( code: Char('j'), modifiers: "")),

          popup_up: Some(( code: Char('p'), modifiers: "CONTROL")),
          popup_down: Some(( code: Char('n'), modifiers: "CONTROL")),
          page_up: Some(( code: Char('b'), modifiers: "CONTROL")),
          page_down: Some(( code: Char('f'), modifiers: "CONTROL")),
          home: Some(( code: Char('g'), modifiers: "")),
          end: Some(( code: Char('G'), modifiers: "SHIFT")),
          shift_up: Some(( code: Char('K'), modifiers: "SHIFT")),
          shift_down: Some(( code: Char('J'), modifiers: "SHIFT")),

          edit_file: Some(( code: Char('I'), modifiers: "SHIFT")),

          status_reset_item: Some(( code: Char('U'), modifiers: "SHIFT")),

          diff_reset_lines: Some(( code: Char('u'), modifiers: "")),
          diff_stage_lines: Some(( code: Char('s'), modifiers: "")),

          stashing_save: Some(( code: Char('w'), modifiers: "")),
          stashing_toggle_index: Some(( code: Char('m'), modifiers: "")),

          stash_open: Some(( code: Char('l'), modifiers: "")),

          abort_merge: Some(( code: Char('M'), modifiers: "SHIFT")),
        '';
      };
      git = {
        inherit (cfg.git) enable userName userEmail;
        package = pkgs.gitFull;
        attributes = [
          "*.pdf diff=pdf"
        ];
        difftastic = {
          inherit (cfg.git) enable;
          display = "inline";
          background = "dark";
          color = "always";
        };
        extraConfig = {
          core = {
            whitespace = "trailing-space,space-before-tab";
            autocrlf = "input";
            editor = config.modules.editor.defaultEditor;
          };
          credential = {
            helper = "libsecret";
          };
          gpg = {
            program = "gpg2";
            format = "openpgp";
          };
          init = {
            defaultBranch = "main";
          };
          commit = {
            gpgsign = true;
          };
          pull = {
            rebase = false;
          };
          push = {
            autoSetupRemote = true;
            default = "current";
          };
          diff = {
            tool = "nvimdiff";
            guitool = "nvimdiff";
          };
          difftool = {
            prompt = false;
            guiDefault = false;
          };
          merge = {
            tool = "nvimdiff";
            guitool = "nvimdiff";
          };
          mergetool = {
            prompt = false;
            guiDefault = false;
            keepBackup = false;
          };
          "mergetool \"vimdiff\"" = {
            layout = "(LOCAL,BASE,REMOTE) / MERGED + (LOCAL,MERGED,REMOTE) + LOCAL,REMOTE + (LOCAL,MERGED) / (REMOTE,MERGED) + (BASE,LOCAL) / (BASE,REMOTE)";
          };
        };
      };
    };
  };
}
