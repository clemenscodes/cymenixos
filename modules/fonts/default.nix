{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  font = "Iosevka";
  monospace = "${font} Nerd Font Mono";
  sansSerif = "${font} Nerd Font";
  serif = "${font} Nerd Font";
  size = 8;
  uiFontAliases = ["system-ui" "Ubuntu" "Droid Sans"];
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
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
          ${
            lib.concatMapStrings (family: ''
              <match target="pattern">
                <test name="family"><string>${family}</string></test>
                <edit name="family" mode="assign" binding="same"><string>${cfg.fonts.defaultFont}</string></edit>
              </match>
            '')
            uiFontAliases
          }
          </fontconfig>
        '';
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
