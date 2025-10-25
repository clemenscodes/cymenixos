{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = [
    (import ./jetbrains {inherit inputs pkgs lib;})
    (import ./nvim {inherit inputs pkgs lib;})
    (import ./zed {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      editor = {
        enable = lib.mkEnableOption "Enable the best text editor" // {default = false;};
        defaultEditor = lib.mkOption {
          type = lib.types.str;
          default = "nvim";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.editor.enable) {
    home = {
      sessionVariables = {
        EDITOR = cfg.editor.defaultEditor;
      };
    };
  };
}
