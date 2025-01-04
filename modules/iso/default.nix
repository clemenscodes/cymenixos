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
    modules = {
      disk = {
        enable = lib.mkForce false;
      };
      users = {
        isIso = true;
      };
    };
  };
}
