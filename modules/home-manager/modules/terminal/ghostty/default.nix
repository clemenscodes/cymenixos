{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.terminal;
in {
  options = {
    modules = {
      terminal = {
        ghostty = {
          enable = lib.mkEnableOption "Enable ghostty" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ghostty.enable) {
    home = {
      packages = [pkgs.ghostty];
    };
  };
}
