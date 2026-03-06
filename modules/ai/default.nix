{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./claude {inherit inputs pkgs lib;})
    (import ./ollama {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      ai = {
        enable = lib.mkEnableOption "Enable AI support";
      };
    };
  };
}
