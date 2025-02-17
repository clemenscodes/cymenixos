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
        drivers = [pkgs.hplip];
        openFirewall = true;
      };
    };
    environment = {
      systemPackages = [
        pkgs.hplip
        pkgs.cups
        pkgs.system-config-printer
        unfreePkgs.hplipWithPlugin
      ];
    };
  };
}
