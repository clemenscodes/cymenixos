{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./rclone {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      storage = {
        enable = lib.mkEnableOption "Enable storage" // {default = false;};
      };
    };
  };
}
