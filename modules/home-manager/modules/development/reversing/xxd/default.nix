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
          xxd = {
            enable = lib.mkEnableOption "Enable xxd" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.xxd.enable) {
    home = {
      packages = [pkgs.unixtools.xxd];
    };
  };
}
