{lib, ...}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.terminal;
in {
  imports = [(import ./theme {inherit lib;})];
  options = {
    modules = {
      terminal = {
        kitty = {
          enable = lib.mkEnableOption "Enable kitty" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.kitty.enable) {
    programs = {
      kitty = {
        inherit (cfg.kitty) enable;
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
          allow_remote_control = "socket-only";
          listen_on = "unix:/tmp/kitty";
        };
      };
    };
    xdg = {
      mimeApps = {
        associations = {
          added = {
            "x-scheme-handler/http" = ["brave.desktop"];
          };
        };
        defaultApplications = {
          "text/html" = ["brave.desktop"];
        };
      };
    };
  };
}
