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
          programs.voxtype = {
            enable = true;
            package = pkgs.voxtype-vulkan;
            service.enable = true;
            engine = "whisper";
            model.name = "large-v3-turbo";
            settings = {
              hotkey.enabled = false;
              whisper.language = "en";
            };
          };
        };
      };
    };
  };
}
