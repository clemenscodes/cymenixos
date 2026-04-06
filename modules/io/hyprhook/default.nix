{
  inputs,
  lib,
  ...
}: {
  config,
  ...
}: let
  cfg = config.modules.io;
  hyprhookModuleAvailable = inputs ? hyprhook;
  windowRule = lib.types.submodule {
    options = {
      class = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "^gamescope$";
        description = ''
          Regex matched against the window class.
          Omit to match any class.
        '';
      };
      title = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Counter-Strike 2";
        description = ''
          Regex matched against the window title.
          Omit to match any title. AND-ed with class.
        '';
      };
      on_open = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["obs-cli start-recording"];
        description = "Shell commands to run when a matching window is created.";
      };
      on_close = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["obs-cli stop-recording"];
        description = "Shell commands to run when a matching window is destroyed.";
      };
      on_focus = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["wootswitch switch CS2"];
        description = "Shell commands to run when a matching window gains focus.";
      };
      on_unfocus = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["wootswitch switch Default"];
        description = "Shell commands to run when a matching window loses focus.";
      };
    };
  };
in {
  imports = lib.optional hyprhookModuleAvailable inputs.hyprhook.nixosModules.default;
  options = {
    modules = {
      io = {
        hyprhook = {
          enable = lib.mkEnableOption "Enable hyprhook — Hyprland window event hook runner";
          windows = lib.mkOption {
            type = lib.types.listOf windowRule;
            default = [];
            description = ''
              Window hook rules. Each entry matches windows by class and/or title
              (both are regexes, AND-ed) and runs shell commands on lifecycle events.
            '';
            example = lib.literalExpression ''
              [
                {
                  class      = "^gamescope$";
                  title      = "Counter-Strike 2";
                  on_focus   = [ "wootswitch switch CS2" ];
                  on_unfocus = [ "wootswitch switch Default" ];
                }
              ]
            '';
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprhook.enable && hyprhookModuleAvailable) {
    services.hyprhook = {
      enable = true;
      windows = cfg.hyprhook.windows;
    };
    systemd.user.services.hyprhook = {
      description = "hyprhook Hyprland window event hook runner";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${config.services.hyprhook.finalPackage}/bin/hyprhook";
        Restart = "on-failure";
        RestartSec = "1s";
      };
    };
  };
}
