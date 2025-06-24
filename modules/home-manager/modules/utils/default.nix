{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./bat {inherit inputs pkgs lib;})
    (import ./fzf {inherit inputs pkgs lib;})
    (import ./gparted {inherit inputs pkgs lib;})
    (import ./lpi {inherit inputs pkgs lib;})
    (import ./lsusb {inherit inputs pkgs lib;})
    (import ./p7zip {inherit inputs pkgs lib;})
    (import ./nix-prefetch-github {inherit inputs pkgs lib;})
    (import ./nix-prefetch-git {inherit inputs pkgs lib;})
    (import ./ripgrep {inherit inputs pkgs lib;})
    (import ./tldr {inherit inputs pkgs lib;})
    (import ./unzip {inherit inputs pkgs lib;})
    (import ./wget {inherit inputs pkgs lib;})
    (import ./zip {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      utils = {
        enable = lib.mkEnableOption "Enable useful utils" // {default = false;};
      };
    };
  };
}
