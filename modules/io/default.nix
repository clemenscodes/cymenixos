{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./android {inherit inputs pkgs lib;})
    (import ./fuse {inherit inputs pkgs lib;})
    (import ./printing {inherit inputs pkgs lib;})
    (import ./sound {inherit inputs pkgs lib;})
    (import ./udisks {inherit inputs pkgs lib;})
    (import ./xremap {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      io = {
        enable = lib.mkEnableOption "Enable IO" // {default = false;};
      };
    };
  };
}
