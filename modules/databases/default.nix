{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./mongodb {inherit inputs pkgs lib;})
    (import ./postgres {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      databases = {
        enable = lib.mkEnableOption "Enable databases" // {default = false;};
      };
    };
  };
}
