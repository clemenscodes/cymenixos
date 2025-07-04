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
          radare2 = {
            enable = lib.mkEnableOption "Enable radare2" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.radare2.enable) {
    home = {
      packages = [
        pkgs.radare2
      ];
    };
  };
}
