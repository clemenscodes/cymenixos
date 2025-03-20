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
  cfg = config.modules.gaming;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) name;
in {
  options = {
    modules = {
      gaming = {
        lutris = {
          enable = lib.mkEnableOption "Enable lutris" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.lutris.enable) {
    environment = {
      systemPackages = [
        (pkgs.lutris.override {
          extraPkgs = pkgs: [
            pkgs.winetricks
            pkgs."wine-wow64-bleeding-10.3"
            pkgs."wine-wow64-bleeding-winetricks-10.3"
            pkgs.curl
            pkgs.samba
            pkgs.jansson
            pkgs.gnutls
            pkgs.protobuf
            pkgs.python313Packages.protobuf
            pkgs.vulkan-tools
            pkgs.vulkan-loader
            pkgs.vulkan-validation-layers
            pkgs.vulkan-extension-layer
            pkgs.libdrm
            pkgs.mesa
            pkgs.driversi686Linux.mesa
          ];
          extraLibraries = pkgs: [
            pkgs.samba
            pkgs.jansson
            pkgs.gnutls
            pkgs.protobuf
            pkgs.python313Packages.protobuf
            pkgs.vulkan-tools
            pkgs.vulkan-loader
            pkgs.vulkan-validation-layers
            pkgs.vulkan-extension-layer
            pkgs.libdrm
            pkgs.mesa
            pkgs.driversi686Linux.mesa
          ];
        })
      ];
      persistence = {
        ${persistPath} = {
          users = {
            ${name} = {
              directories = [
                ".cache/lutris"
                ".local/share/lutris"
              ];
            };
          };
        };
      };
    };
  };
}
