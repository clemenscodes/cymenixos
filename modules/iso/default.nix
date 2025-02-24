{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = ["${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"];
  options = {
    modules = {
      iso = {
        enable = lib.mkEnableOption "Enable ISO image" // {default = false;};
        fast = lib.mkEnableOption "Use fast compression" // {default = false;};
      };
    };
  };
  config = lib.mkIf cfg.iso.enable {
    isoImage = lib.mkIf cfg.iso.fast {
      squashfsCompression = "gzip -Xcompression-level 1";
    };
    system = {
      installer = {
        channel = {
          enable = false;
        };
      };
    };
    modules = {
      users = {
        isIso = true;
      };
      networking = {
        enable = true;
        dbus = {
          enable = true;
        };
        firewall = {
          enable = true;
        };
        wireless = {
          enable = true;
        };
      };
    };
    home-manager = {
      users = {
        ${config.modules.users.user} = {
          modules = {
            networking = {
              enable = true;
              nm = {
                enable = true;
              };
            };
          };
        };
      };
    };
  };
}
