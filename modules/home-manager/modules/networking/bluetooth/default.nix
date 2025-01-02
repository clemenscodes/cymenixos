{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./blueman {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      networking = {
        bluetooth = {
          enable = lib.mkEnableOption "Enable bluetooth" // {default = false;};
        };
      };
    };
  };
}
