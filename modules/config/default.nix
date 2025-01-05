{
  inputs,
  pkgs,
  lib,
  cymenixos,
  ...
}: {...}: {
  imports = [
    (import ./cachix {inherit inputs pkgs lib;})
    (import ./nix {inherit inputs pkgs lib cymenixos;})
  ];
  options = {
    modules = {
      config = {
        enable = lib.mkEnableOption "Enable common configurations" // {default = false;};
      };
    };
  };
}
