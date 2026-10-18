{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./herdr {inherit inputs pkgs lib;})
    (import ./tmux {inherit inputs pkgs lib;})
    (import ./zellij {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      shell = {
        multiplexers = {
          enable = lib.mkEnableOption "Enable terminal multiplexers" // {default = false;};
        };
      };
    };
  };
}
