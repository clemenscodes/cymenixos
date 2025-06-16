{
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.development.reversing;
in {
  options = {
    modules = {
      development = {
        reversing = {
          radare = {
            enable = lib.mkEnableOption "Enable radare" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.radare.enable) {
    home = {
      packages = [
        pkgs.radare2
      ];
    };
  };
}
