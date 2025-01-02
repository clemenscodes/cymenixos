{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./audacity {inherit inputs pkgs lib;})
    (import ./interfaces {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        audio = {
          enable = lib.mkEnableOption "Enable audio processing" // {default = false;};
        };
      };
    };
  };
}
