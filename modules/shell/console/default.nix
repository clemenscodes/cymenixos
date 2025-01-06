{lib, ...}: {config, ...}: let
  cfg = config.modules.shell;
  inherit (cfg.console) enable;
in {
  options = {
    modules = {
      shell = {
        console = {
          enable = lib.mkEnableOption "Enable a neat console configuration" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && enable) {
    services = {
      xserver = {
        xkb = {
          layout = config.modules.locale.defaultLocale;
        };
      };
    };
    console = {
      earlySetup = enable;
      useXkbConfig = enable;
    };
  };
}
