{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.themes;
in {
  config = lib.mkIf (cfg.enable && cfg.catppuccin.enable && config.modules.home-manager.enable && !config.modules.airgap.offline) {
    home-manager = {
      users = {
        ${config.modules.users.user} = {
          imports = [inputs.catppuccin.homeModules.catppuccin];
          catppuccin = {
            inherit (cfg.catppuccin) enable flavor accent;
            mako = {
              enable = false;
            };
            yazi = {
              enable = false;
            };
            firefox = {
              enable = false;
            };
          };
        };
      };
    };
  };
}
