{lib, ...}: {config, ...}: let
  cfg = config.modules.display;
in {
  options = {
    modules = {
      display = {
        sunshine = {
          enable = lib.mkEnableOption "Enable Sunshine GPU-accelerated remote desktop streaming (pair with Moonlight)" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.sunshine.enable) {
    services = {
      sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
      };
    };
  };
}
