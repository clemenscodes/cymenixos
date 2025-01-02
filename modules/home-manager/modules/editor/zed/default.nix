{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.editor;
in {
  options = {
    modules = {
      editor = {
        zed = {
          enable = lib.mkEnableOption "Enable zed" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.zed.enable) {
    home = {
      packages = [pkgs.zed-editor];
    };
  };
}
