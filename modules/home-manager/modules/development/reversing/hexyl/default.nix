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
          hexyl = {
            enable = lib.mkEnableOption "Enable hexyl" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hexyl.enable) {
    home = {
      packages = [pkgs.hexyl];
    };
  };
}
