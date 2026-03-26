{
  inputs,
  lib,
  ...
}:
{ config, system, ... }:
let
  cfg = config.modules.io;
  inherit (config.modules.users) user;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
  sc0710 = config.boot.kernelPackages.callPackage ./sc0710.nix { };
  sc0710-cli = pkgs.callPackage ./sc0710-cli.nix { };
  sc0710-firmware = pkgs.callPackage ./sc0710-firmware.nix { };
in
{
  options = {
    modules = {
      io = {
        elgato = {
          enable = lib.mkEnableOption "Enable YUAN/Elgato sc0710 PCIe capture card driver (12ab:0710)" // {
            default = false;
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.elgato.enable) {
    boot = {
      extraModulePackages = [ sc0710 ];
      kernelModules = [ "sc0710" ];
    };
    hardware = {
      firmware = [ sc0710-firmware ];
    };
    environment = {
      systemPackages = [
        pkgs.v4l-utils
        pkgs.ffmpeg
        sc0710-cli
      ];
    };
    users = {
      users = {
        ${user} = {
          extraGroups = [ "video" ];
        };
      };
    };
  };
}
