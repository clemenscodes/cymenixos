{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = [
    (import ./ghostty {inherit inputs pkgs lib;})
    (import ./kitty {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      terminal = {
        enable = lib.mkEnableOption "Enable a great terminal" // {default = false;};
        defaultTerminal = lib.mkOption {
          type = lib.types.enum ["kitty" "ghostty"];
          default = "kitty";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.terminal.enable) {
    home = {
      sessionVariables = {
        TERMINAL = cfg.terminal.defaultTerminal;
      };
    };
  };
}
