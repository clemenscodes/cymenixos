{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./bluetooth {inherit inputs pkgs lib;})
    (import ./irc {inherit inputs pkgs lib;})
    (import ./nm {inherit inputs pkgs lib;})
    (import ./proxy {inherit inputs pkgs lib;})
    (import ./wireshark {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      networking = {
        enable = lib.mkEnableOption "Enable networking" // {default = false;};
      };
    };
  };
}
