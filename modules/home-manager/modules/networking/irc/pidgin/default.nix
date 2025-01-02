{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.networking.irc;
in {
  options = {
    modules = {
      networking = {
        irc = {
          pidgin = {
            enable = lib.mkEnableOption "Enable pidgin" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.pidgin.enable) {
    programs = {
      pidgin = {
        inherit (cfg.pidgin) enable;
        plugins = [
          pkgs.pidginPackages.pidgin-otr
          pkgs.pidginPackages.purple-discord
          pkgs.pidginPackages.pidgin-indicator
        ];
      };
    };
  };
}
