{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.development;
in {
  imports = [
    (import ./gitui {inherit inputs pkgs lib;})
    (import ./lazygit {inherit inputs pkgs lib;})
  ];
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
          signing = {
            enable = lib.mkEnableOption "Enable commit signing using PGP" // {default = false;};
            gpgFingerprint = lib.mkOption {
              type = lib.types.str;
              default = null;
            };
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
            program = "${pkgs.gnupg}/bin/gpg2";
            format = "openpgp";
          };
          init = {
            defaultBranch = "main";
          };
          user = lib.mkIf cfg.git.signing.enable {
            signingkey = cfg.git.signing.gpgFingerprint;
          };
          commit = {
            gpgsign = cfg.git.signing.enable;
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
