{lib, ...}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        fuse = {
          enable = lib.mkEnableOption "Enable fuse" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.fuse.enable) {
    programs = {
      fuse = {
        userAllowOther = cfg.fuse.enable;
      };
    };
  };
}
