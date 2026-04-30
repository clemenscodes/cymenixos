{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming;
in {
  imports = [inputs.w3c.nixosModules.${system}.default];
  options = {
    modules = {
      gaming = {
        w3champions = {
          enable = lib.mkEnableOption "Enable W3Champions" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.w3champions.enable) {
    w3champions = {
      inherit (cfg.w3champions) enable;
      inherit (config.modules.users) name;
    };

    home-manager = lib.mkIf config.modules.home-manager.enable {
      users.${config.modules.users.user} = {
        wayland.windowManager.hyprland.settings = {
          windowrule = [
            "content game, tile on, match:class ^(battle.net.exe)$, match:title ^(Battle.net)$"
            "content game, workspace 2, center 1, float on, size (monitor_w*0.8) (monitor_h*0.8), match:class ^(w3champions.exe)$, match:title ^(W3Champions)$"
            "workspace 3, match:class ^(warcraft iii.exe)$"
            "fullscreen on, match:class ^(warcraft iii.exe)$"
            "immediate on, match:class ^(warcraft iii.exe)$"
          ];
        };
      };
    };
  };
}
