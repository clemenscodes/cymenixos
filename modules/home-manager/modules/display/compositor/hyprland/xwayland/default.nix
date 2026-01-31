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
            enable = false;
          };
          extraConfig =
            /*
            hyprlang
            */
            ''
              windowrulev2 = opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$
              windowrulev2 = noanim,class:^(xwaylandvideobridge)$
              windowrulev2 = nofocus,class:^(xwaylandvideobridge)$
              windowrulev2 = noinitialfocus,class:^(xwaylandvideobridge)$
            '';
        };
      };
    };
  };
}
