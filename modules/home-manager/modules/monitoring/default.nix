{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./btop {inherit inputs pkgs lib;})
    (import ./ncdu {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      monitoring = {
        enable = lib.mkEnableOption "Enable tools for monitoring the system" // {default = false;};
      };
    };
  };
}
