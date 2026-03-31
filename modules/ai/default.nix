{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./claude {inherit inputs pkgs lib;})
    (import ./mcp {inherit pkgs lib;})
    (import ./ollama {inherit inputs pkgs lib;})
    (import ./vibevoice {inherit inputs pkgs lib;})
    (import ./voxtype {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      ai = {
        enable = lib.mkEnableOption "Enable AI support";
      };
    };
  };
}
