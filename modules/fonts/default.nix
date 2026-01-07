{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  font = "Lilex";
  monospace = "${font} Nerd Font Mono";
  sansSerif = "${font} Nerd Font";
  serif = "${font} Nerd Font";
  size = 8;
in {
  options = {
    modules = {
      fonts = {
        enable = lib.mkEnableOption "Enable fonts" // {default = false;};
        defaultFont = lib.mkOption {
          type = lib.types.str;
          default = sansSerif;
        };
        size = lib.mkOption {
          type = lib.types.int;
          default = size;
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.fonts.enable) {
    fonts = {
      fontconfig = {
        inherit (cfg.fonts) enable;
        defaultFonts = {
          monospace = ["${monospace}"];
          sansSerif = ["${sansSerif}"];
          serif = ["${serif}"];
        };
      };
      fontDir = {
        inherit (cfg.fonts) enable;
      };
      packages = [
        pkgs.nerd-fonts.iosevka
        pkgs.nerd-fonts.victor-mono
        pkgs.nerd-fonts.lilex
      ];
    };
  };
}
