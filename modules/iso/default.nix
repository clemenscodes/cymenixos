{
  inputs,
  lib,
  ...
}: {...}: {
  imports = ["${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"];
  isoImage = {
    squashfsCompression = "gzip -Xcompression-level 1"; # Remove this for smaller image size when writing to USB
  };
  modules = {
    disk = {
      enable = lib.mkForce false;
    };
  };
}
