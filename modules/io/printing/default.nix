{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.io;
  unfreePkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "hplip"
        ];
    };
  };
in {
  options = {
    modules = {
      io = {
        printing = {
          enable = lib.mkEnableOption "Enable printing services" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.printing.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.persistPath} = {
          users = {
            ${config.modules.users.name} = {
              directories = [
                ".sane"
                ".hplip"
              ];
            };
          };
        };
      };
    };
    users = {
      users = {
        ${config.modules.users.name} = {
          extraGroups = [
            "scanner"
            "lp"
          ];
        };
      };
    };
    hardware = {
      sane = {
        inherit (cfg.printing) enable;
        extraBackends = [unfreePkgs.hplipWithPlugin];
      };
    };
    services = {
      avahi = {
        inherit (cfg.printing) enable;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          inherit (cfg.printing) enable;
          userServices = true;
        };
      };
      printing = {
        inherit (cfg.printing) enable;
        browsing = true;
        listenAddresses = ["127.0.0.1:631"];
        allowFrom = ["127.0.0.1"];
        defaultShared = true;
        drivers = [unfreePkgs.hplipWithPlugin];
        openFirewall = true;
      };
    };
    environment = {
      systemPackages = [
        pkgs.hplip
        pkgs.cups
        pkgs.system-config-printer
        pkgs.xsane
        pkgs.simple-scan
        unfreePkgs.hplipWithPlugin
      ];
    };
  };
}
