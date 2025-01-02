{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media.games;
in {
  options = {
    modules = {
      media = {
        games = {
          stockfish = {
            enable = lib.mkEnableOption "Enable stockfish engine" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.stockfish.enable) {
    home = {
      packages = [pkgs.stockfish];
    };
  };
}
