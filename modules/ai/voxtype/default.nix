{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.ai;
  inherit (config.modules.users) user;
  voxtype = pkgs.voxtype-vulkan;
in {
  options = {
    modules = {
      ai = {
        voxtype = {
          enable = lib.mkEnableOption "Enable voxtype speech to text";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.voxtype.enable) {
    home-manager = {
      users = {
        ${user} = {
          imports = [inputs.voxtype.homeManagerModules.default];
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  bind = SUPER SHIFT, T, exec, ${voxtype}/bin/voxtype record start
                  bindr = SUPER SHIFT, T, exec, ${voxtype}/bin/voxtype record stop
                '';
              };
            };
          };
          programs = {
            voxtype = {
              inherit (cfg.voxtype) enable;
              package = voxtype;
              service = {
                inherit (cfg.voxtype) enable;
              };
              engine = "whisper";
              model = {
                name = "large-v3-turbo";
              };
              settings = {
                state_file = "auto";
                status = {
                  icon_theme = "emoji";
                };
                hotkey = {
                  enabled = false;
                };
                whisper = {
                  language = "en";
                  translate = false;
                };
              };
            };
          };
        };
      };
    };
  };
}
