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
          imports = [inputs.catppuccin.homeManagerModules.catppuccin];
          catppuccin = {
            inherit (cfg.catppuccin) enable flavor accent;
            gitea = {
              enable = lib.mkForce false;
            };
            forgejo = {
              enable = lib.mkForce false;
            };
          };
        };
      };
    };
  };
}
