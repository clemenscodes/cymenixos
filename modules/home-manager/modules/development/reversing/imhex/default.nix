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
          imhex = {
            enable = lib.mkEnableOption "Enable imhex" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.imhex.enable) {
    home = {
      packages = [pkgs.imhex];
    };
  };
}
