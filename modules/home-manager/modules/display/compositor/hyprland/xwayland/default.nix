{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display.compositor.hyprland;
in {
  options = {
    modules = {
      display = {
        compositor = {
          hyprland = {
            xwayland = {
              enable = lib.mkEnableOption "Enable xwayland" // {default = false;};
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.xwayland.enable) {
    home = {
      packages = [pkgs.xwaylandvideobridge];
    };
    wayland = {
      windowManager = {
        hyprland = {
          xwayland = {
            enable = cfg.xwayland.enable;
          };
          extraConfig =
            /*
            lua
            */
            ''
              hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, opacity = "0.0 override 0.0 override" })
              hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_anim = true })
              hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_focus = true })
              hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_initial_focus = true })
            '';
        };
      };
    };
  };
}
