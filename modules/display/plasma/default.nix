{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.display;
  pkgs = inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        kdePackages = prev.kdePackages.overrideScope (kdeFinal: kdePrev: {
          powerdevil = kdePrev.powerdevil.overrideAttrs (oldAttrs: {
            patches = oldAttrs.patches or [];
          });
        });
      })
    ];
  };
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
          elisa
        ];
      };
    };
    services = {
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland = {
            enable = true;
          };
          settings = {
            General = {
              DisplayServer = "wayland";
            };
          };
        };
      };
      desktopManager = {
        plasma6 = {
          enable = true;
          enableQt5Integration = true;
        };
      };
    };
  };
}
