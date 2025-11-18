{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules;
in {
  imports = [
    (import ./jetbrains {inherit inputs pkgs lib;})
    (import ./nvim {inherit inputs pkgs lib;})
    (import ./vscode {inherit inputs pkgs lib;})
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
      persistence = lib.mkIf osConfig.modules.boot.enable {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [
            ".vscode"
            ".config/Code"
          ];
        };
      };
    };
  };
}
