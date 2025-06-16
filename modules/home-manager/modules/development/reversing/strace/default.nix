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
          strace = {
            enable = lib.mkEnableOption "Enable strace" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.strace.enable) {
    home = {
      packages = [
        pkgs.strace
      ];
    };
  };
}
