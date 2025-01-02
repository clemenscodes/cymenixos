{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./scarlett {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        audio = {
          interfaces = {
            enable = lib.mkEnableOption "Enable audio interfaces" // {default = false;};
          };
        };
      };
    };
  };
}
