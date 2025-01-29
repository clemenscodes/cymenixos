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
          user = {
            signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
          };
          gpg = {
            program = "gpg2";
            format = "ssh";
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
