{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./mpv {inherit inputs pkgs lib;})
    (import ./mpris {inherit inputs pkgs lib;})
    (import ./obs {inherit inputs pkgs lib;})
    (import ./vhs {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        video = {
          enable = lib.mkEnableOption "Enable video" // {default = false;};
        };
      };
    };
  };
}
