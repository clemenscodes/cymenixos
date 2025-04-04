{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
  inherit (config.modules.users) user;
in {
  options = {
    modules = {
      io = {
        android = {
          enable = lib.mkEnableOption "Enable android system service" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.android.enable) {
    programs = {
      adb = {
        inherit (cfg.android) enable;
      };
    };
    users = {
      users = {
        ${user} = {
          extraGroups = ["adbusers" "kvm"];
        };
      };
    };
    services = {
      udev = {
        packages = [pkgs.android-udev-rules];
      };
    };
  };
}
