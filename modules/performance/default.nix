{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: {
  imports = [
    (import ./auto-cpufreq {inherit inputs pkgs lib;})
    (import ./power {inherit inputs pkgs lib;})
    (import ./thermald {inherit inputs pkgs lib;})
    (import ./tlp {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      performance = {
        enable = lib.mkEnableOption "Enable performance tweaks" // {default = false;};
      };
    };
  };
  config = lib.mkIf (config.modules.enable && config.modules.performance.enable) {
    systemd = {
      services = {
        "getty@tty1" = {
          enable = false;
        };
        "autovt@tty1" = {
          enable = false;
        };
        "getty@tty7" = {
          enable = false;
        };
        "autovt@tty7" = {
          enable = false;
        };
      };
    };
  };
}
