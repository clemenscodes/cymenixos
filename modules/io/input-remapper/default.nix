{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        input-remapper = {
          enable = lib.mkEnableOption "Enable input-remapper service" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.input-remapper.enable) {
    programs = {
      input-remapper = {
        inherit (cfg.input-remapper) enable;
      };
    };
  };
}
