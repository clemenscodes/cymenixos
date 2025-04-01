{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display;
in {
  options = {
    modules = {
      display = {
        plasma = {
          enable = lib.mkEnableOption "Enable plasma" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.plasma.enable) {
    environment = {
      plasma6 = {
        excludePackages = with pkgs.kdePackages; [
          plasma-browser-integration
          konsole
          oxygen
        ];
      };
    };
    services = {
      xserver = {
        enable = true;
      };
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
        };
      };
      desktopManager = {
        plasma6 = {
          enable = true;
        };
      };
    };
  };
}
