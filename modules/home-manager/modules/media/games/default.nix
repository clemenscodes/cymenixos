{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./stockfish {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        games = {
          enable = lib.mkEnableOption "Enable games" // {default = false;};
        };
      };
    };
  };
}
