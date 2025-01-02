{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./alsa-scarlett-gui {inherit inputs pkgs lib;})
    (import ./scarlett2 {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        audio = {
          interfaces = {
            scarlett = {
              enable = lib.mkEnableOption "Enable scarlett audio interfaces" // {default = false;};
            };
          };
        };
      };
    };
  };
}
