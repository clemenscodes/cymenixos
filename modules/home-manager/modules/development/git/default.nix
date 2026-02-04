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
        inherit (cfg.git) enable;
        package = pkgs.gitFull;
        attributes = [
          "*.pdf diff=pdf"
        ];
        signing = lib.mkIf cfg.git.signing.enable {
          signByDefault = true;
          format = "openpgp";
          signer = "${pkgs.gnupg}/bin/gpg2";
          key = cfg.git.signing.gpgFingerprint;
        };
        settings = {
          user = let
            inherit (cfg.git) userName userEmail;
          in {
            name = userName;
            email = userEmail;
          };
          core = {
            whitespace = "trailing-space,space-before-tab";
            autocrlf = "input";
            editor = config.modules.editor.defaultEditor;
          };
          credential = {
            helper = "libsecret";
          };
          init = {
            defaultBranch = "main";
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
