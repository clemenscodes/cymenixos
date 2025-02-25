{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.themes;
in {
  config = lib.mkIf (cfg.enable && cfg.catppuccin.enable && config.modules.home-manager.enable) {
    home-manager = {
      users = {
        ${config.modules.users.user} = {
          imports = [inputs.catppuccin.homeManagerModules.catppuccin];
          # catppuccin = {
          #   inherit (cfg.catppuccin) enable flavor accent;
          #
          #   # Disable IFD
          #   cava = {
          #     enable = lib.mkForce false;
          #   };
          #   fzf = {
          #     enable = lib.mkForce false;
          #   };
          #   gh-dash = {
          #     enable = lib.mkForce false;
          #   };
          #   mako = {
          #     enable = lib.mkForce false;
          #   };
          #   imv = {
          #     enable = lib.mkForce false;
          #   };
          #   starship = {
          #     enable = lib.mkForce false;
          #   };
          #   swaylock = {
          #     enable = lib.mkForce false;
          #   };
          # };
        };
      };
    };
  };
}
