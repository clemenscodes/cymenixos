{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming.emulation;
in {
  options = {
    modules = {
      gaming = {
        emulation = {
          mgba = {
            enable = lib.mkEnableOption "Enable mGBA emulation (Game Boy Advance)" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mgba.enable) {
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${config.modules.users.user} = {
          home = {
            packages = [pkgs.mgba];
          };
        };
      };
    };
  };
}
