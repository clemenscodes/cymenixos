{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./vps {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      operations = {
        enable = lib.mkEnableOption "Enable operations" // {default = false;};
      };
    };
  };
}
