{
  config,
  osConfig,
  lib,
  ...
}: let
  cfg = config.modules.terminal;
in {
  imports = [./theme];
  options = {
    modules = {
      terminal = {
        kitty = {
          enable = lib.mkEnableOption "Enable kitty" // {default = cfg.enable;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.kitty.enable) {
    programs = {
      kitty = {
        enable = cfg.kitty.enable;
        shellIntegration = {
          enableZshIntegration = config.modules.shell.zsh.enable;
        };
        font = {
          inherit (osConfig.modules.fonts) size;
          name = "${osConfig.modules.fonts.defaultFont}";
        };
        settings = {
          dynamic_background_opacity = "yes";
          enable_audio_bell = false;
          shell = config.modules.shell.defaultShell;
          confirm_os_window_close = 0;
          open_url_with = "default";
        };
      };
    };
  };
}
