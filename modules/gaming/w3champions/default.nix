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
        wayland.windowManager.hyprland.extraConfig = ''
          hl.window_rule({ match = { class = "^(battle.net.exe)$", title = "^(Battle.net)$" }, tile = true })
          hl.window_rule({ match = { class = "^(w3champions.exe)$", title = "^(W3Champions)$" }, workspace = "2", center = true, float = true })
          hl.window_rule({ match = { class = "^(warcraft iii.exe)$" }, workspace = "3" })
          hl.window_rule({ match = { class = "^(warcraft iii.exe)$" }, fullscreen = true })
        '';
      };
    };
  };
}
