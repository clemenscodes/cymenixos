{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display;
in {
  imports = [
    (import ./swaync {inherit pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        notifications = {
          enable = lib.mkEnableOption "Enable notifications" // {default = false;};
          defaultNotificationCenter = lib.mkOption {
            type = lib.types.enum ["swaync"];
            default = "swaync";
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.notifications.enable) {
    home = {
      packages = [pkgs.libnotify];
    };
  };
}
