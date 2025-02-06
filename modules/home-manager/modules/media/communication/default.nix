{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./discord {inherit inputs pkgs lib;})
    (import ./element {inherit inputs pkgs lib;})
    (import ./teams {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        communication = {
          enable = lib.mkEnableOption "Enable communication" // {default = false;};
        };
      };
    };
  };
}
