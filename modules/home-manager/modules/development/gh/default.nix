{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.development;
in {
  imports = [(import ./plugins {inherit inputs pkgs lib;})];
  options = {
    modules = {
      development = {
        gh = {
          enable = lib.mkEnableOption "Enable GitHub CLI" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gh.enable) {
    programs = {
      gh = {
        inherit (cfg.gh) enable;
        settings = {
          version = 1;
          editor = config.modules.editor.defaultEditor;
          git_protocol = "ssh";
          browser = config.modules.browser.defaultBrowser or "firefox";
        };
        gitCredentialHelper = {
          enable = true;
        };
      };
    };
  };
}
