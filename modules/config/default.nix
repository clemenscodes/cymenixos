{
  inputs,
  pkgs,
  lib,
  cymenixos,
  ...
}: {...}: {
  imports = [
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
