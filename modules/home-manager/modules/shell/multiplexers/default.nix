{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
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
