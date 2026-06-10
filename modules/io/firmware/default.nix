{lib, ...}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        firmware = {
          enable =
            lib.mkEnableOption "Firmware updates via fwupd (LVFS)"
            // {default = true;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.firmware.enable) {
    services.fwupd.enable = true;
  };
}
