{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.ai;
  inherit (config.modules.boot.impermanence) persistPath;
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
            package = inputs.voxtype.packages.${system}.vulkan;
            service.enable = true;
            engine = "whisper";
            model.name = "base.en";
            settings = {
              hotkey.enabled = false;
              whisper.language = "en";
            };
          };
          systemd.user.services.voxtype.Service.Environment = [
            "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
          ];
          home = {
            persistence = lib.mkIf (config.modules.boot.enable) {
              "${persistPath}" = {
                directories = [];
              };
            };
          };
        };
      };
    };
  };
}
