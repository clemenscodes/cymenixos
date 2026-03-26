{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
  inherit (config.modules.users) user;
  sc0710 = config.boot.kernelPackages.callPackage ./sc0710.nix {};
in {
  options = {
    modules = {
      io = {
        elgato = {
          enable = lib.mkEnableOption "Enable YUAN/Elgato sc0710 PCIe capture card driver (12ab:0710)" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.elgato.enable) {
    boot = {
      extraModulePackages = [sc0710];
      kernelModules = ["sc0710"];
    };
    environment = {
      systemPackages = [
        pkgs.v4l-utils
        pkgs.ffmpeg
      ];
    };
    users = {
      users = {
        ${user} = {
          extraGroups = ["video"];
        };
      };
    };
  };
}
