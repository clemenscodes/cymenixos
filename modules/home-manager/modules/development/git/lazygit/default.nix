{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.development.git;
in {
  options = {
    modules = {
      development = {
        git = {
          lazygit = {
            enable = lib.mkEnableOption "Enable lazygit" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.lazygit.enable) {
    home = {
      packages = [pkgs.lazygit];
      file = {
        ".config/lazygit/config.yml" = {
          text = ''
            confirmOnQuit: false
            disableStartupPopups: true
            git:
              allBranchesLogCmd: git log --graph --all --color=always --abbrev-commit --decorate --date=relative  --pretty=medium
              autoFetch: true
              autoRefresh: true
              autoStageResolvedConflicts: true
              branchLogCmd: git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --
              branchPrefix: ''''
              commit:
                autoWrapCommitMessage: true
                autoWrapWidth: 72
                signOff: false
              commitPrefix:
                - pattern: ''''
                  replace: ''''
              disableForcePushing: false
              fetchAll: true
              log:
                order: topo-order
                showGraph: always
                showWholeGraph: false
              mainBranches:
                - master
                - main
              merging:
                args: ''''
                manualCommit: false
                squashMergeMessage: Squash merge {{selectedRef}} into {{currentBranch}}
              overrideGpg: false
              paging:
                colorArg: always
                externalDiffCommand: ${pkgs.difftastic}/bin/difft --color=always
                pager: ''''
                useConfig: false
              parseEmoji: false
              skipHookPrefix: WIP
              truncateCopiedCommitHashesTo: 12
            gui:
              animateExplosion: true
              authorColors:
                '*': '#b7bdf8'
              border: rounded
              commandLogSize: 8
              commitAuthorLongLength: 17
              commitAuthorShortLength: 2
              commitHashLength: 8
              commitLength:
                show: true
              enlargedSideViewLocation: left
              expandFocusedSidePanel: false
              expandedSidePanelWeight: 2
              filterMode: substring
              language: auto
              mainPanelSplitMode: flexible
              mouseEvents: true
              nerdFontsVersion: ''''
              portraitMode: auto
              screenMode: normal
              scrollHeight: 2
              scrollOffBehavior: margin
              scrollOffMargin: 2
              scrollPastBottom: true
              shortTimeFormat: 3:04PM
              showBottomLine: true
              showBranchCommitHash: false
              showCommandLog: true
              showDivergenceFromBaseBranch: none
              showFileIcons: true
              showFileTree: true
              showIcons: false
              showListFooter: true
              showNumstatInFilesView: false
              showPanelJumps: true
              showRandomTip: true
              sidePanelWidth: 0.3333
              skipDiscardChangeWarning: false
              skipNoStagedFilesWarning: false
              skipRewordInEditorWarning: false
              skipStashWarning: false
              spinner:
                frames:
                  - '|'
                  - /
                  - '-'
                  - \
                rate: 50
              splitDiff: auto
              statusPanelView: dashboard
              switchTabsWithPanelJumpKeys: false
              switchToFilesAfterStashApply: true
              switchToFilesAfterStashPop: true
              theme:
                activeBorderColor:
                  - '#8aadf4'
                  - bold
                  - green
                  - bold
                cherryPickedCommitBgColor:
                  - '#494d64'
                  - cyan
                cherryPickedCommitFgColor:
                  - '#8aadf4'
                  - blue
                defaultFgColor:
                  - '#cad3f5'
                  - default
                inactiveBorderColor:
                  - '#a5adcb'
                  - default
                inactiveViewSelectedLineBgColor:
                  - bold
                markedBaseCommitBgColor:
                  - yellow
                markedBaseCommitFgColor:
                  - blue
                optionsTextColor:
                  - '#8aadf4'
                  - blue
                searchingActiveBorderColor:
                  - '#eed49f'
                  - cyan
                  - bold
                selectedLineBgColor:
                  - '#363a4f'
                  - blue
                unstagedChangesColor:
                  - '#ed8796'
                  - red
              timeFormat: 02 Jan 06
              wrapLinesInStagingView: true
            keybinding:
              branches:
                checkoutBranchByName: c
                copyPullRequestURL: <c-y>
                createPullRequest: o
                createTag: T
                fastForward: f
                fetchRemote: f
                forceCheckoutBranch: F
                mergeIntoCurrentBranch: M
                pushTag: P
                rebaseBranch: r
                renameBranch: R
                setUpstream: u
                sortOrder: s
                viewGitFlowOptions: i
                viewPullRequestOptions: O
              commits:
                amendToCommit: A
                checkoutCommit: <space>
                cherryPickCopy: C
                copyCommitAttributeToClipboard: y
                createFixupCommit: F
                markCommitAsBaseForRebase: B
                markCommitAsFixup: f
                moveDownCommit: <c-j>
                moveUpCommit: <c-k>
                openInBrowser: o
                openLogMenu: <c-l>
                pasteCommits: V
                pickCommit: p
                renameCommit: r
                renameCommitWithEditor: R
                resetCherryPick: <c-R>
                resetCommitAuthor: a
                revertCommit: t
                squashAboveCommits: S
                squashDown: s
                startInteractiveRebase: i
                tagCommit: T
                viewBisectOptions: b
                viewResetOptions: g
              files:
                amendLastCommit: A
                collapseAll: '-'
                commitChanges: c
                commitChangesWithEditor: C
                commitChangesWithoutHook: w
                confirmDiscard: x
                copyFileInfoToClipboard: y
                expandAll: '='
                fetch: f
                findBaseCommitForFixup: <c-f>
                ignoreFile: i
                openMergeTool: M
                openStatusFilter: <c-b>
                refreshFiles: r
                stashAllChanges: s
                toggleStagedAll: a
                toggleTreeView: '`'
                viewResetOptions: D
                viewStashOptions: S
              status:
                allBranchesLogGraph: a
                checkForUpdate: u
                recentRepos: <enter>
              universal:
                confirm: <enter>
                confirmInEditor: <a-enter>
                copyToClipboard: <c-o>
                createPatchOptionsMenu: <c-p>
                createRebaseOptionsMenu: m
                decreaseContextInDiffView: '{'
                decreaseRenameSimilarityThreshold: (
                diffingMenu: W
                diffingMenuAlt: <c-e>
                edit: e
                executeShellCommand: ':'
                extrasMenu: '@'
                filteringMenu: <c-s>
                goInto: <enter>
                gotoBottom: '>'
                gotoTop: <
                increaseContextInDiffView: '}'
                increaseRenameSimilarityThreshold: )
                jumpToBlock:
                  - '1'
                  - '2'
                  - '3'
                  - '4'
                  - '5'
                new: n
                nextBlock: <right>
                nextBlockAlt: l
                nextBlockAlt2: <tab>
                nextItem: <down>
                nextItemAlt: j
                nextMatch: n
                nextPage: .
                nextScreenMode: +
                nextTab: ']'
                openDiffTool: <c-t>
                openFile: o
                openRecentRepos: <c-r>
                optionMenu: <disabled>
                optionMenuAlt1: '?'
                prevBlock: <left>
                prevBlockAlt: h
                prevBlockAlt2: <backtab>
                prevItem: <up>
                prevItemAlt: k
                prevMatch: N
                prevPage: ','
                prevScreenMode: _
                prevTab: '['
                pullFiles: p
                pushFiles: P
                quit: q
                quitAlt1: <c-c>
                quitWithoutChangingDirectory: Q
                rangeSelectDown: <s-down>
                rangeSelectUp: <s-up>
                redo: <c-z>
                refresh: R
                remove: d
                return: <esc>
                scrollDownMain: <pgdown>
                scrollDownMainAlt1: J
                scrollDownMainAlt2: <c-d>
                scrollLeft: H
                scrollRight: L
                scrollUpMain: <pgup>
                scrollUpMainAlt1: K
                scrollUpMainAlt2: <c-u>
                select: <space>
                startSearch: /
                submitEditorText: <enter>
                togglePanel: <tab>
                toggleRangeSelect: v
                toggleWhitespaceInDiffView: <c-w>
                undo: z
              worktrees:
                viewWorktreeOptions: w
            notARepository: prompt
            os:
              copyToClipboardCmd: ''''
              edit: ''''
              editAtLine: ''''
              editAtLineAndWait: ''''
              editCommand: ''''
              editCommandTemplate: ''''
              editPreset: ''''
              open: ''''
              openCommand: ''''
              openDirInEditor: ''''
              openLink: ''''
              openLinkCommand: ''''
              readFromClipboardCmd: ''''
            promptToReturnFromSubprocess: true
            quitOnTopLevelReturn: false
            refresher:
              fetchInterval: 60
              refreshInterval: 10
            update:
              days: 14
              method: prompt
          '';
        };
      };
    };
  };
}
