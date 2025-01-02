{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./hcloud {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      operations = {
        vps = {
          enable = lib.mkEnableOption "Enable support for controlling VPS" // {default = false;};
        };
      };
    };
  };
}
