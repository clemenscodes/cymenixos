{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  ...
}: let
  cfg = config.modules.io;
  hyprhookModuleAvailable = inputs ? hyprhook;
  commandType = lib.types.listOf lib.types.str;

  ruleType = lib.types.submodule {
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
        type = lib.types.nullOr commandType;
        default = null;
        example = ["obs-cli" "start-recording"];
        description = "Command to run when a matching window is created. First element is the binary, the rest are args.";
      };
      on_close = lib.mkOption {
        type = lib.types.nullOr commandType;
        default = null;
        example = ["obs-cli" "stop-recording"];
        description = "Command to run when a matching window is destroyed. First element is the binary, the rest are args.";
      };
      on_focus = lib.mkOption {
        type = lib.types.nullOr commandType;
        default = null;
        example = ["hyprctl" "dispatch" "submap" "gaming"];
        description = "Command to run when a matching window gains focus. First element is the binary, the rest are args.";
      };
      on_unfocus = lib.mkOption {
        type = lib.types.nullOr commandType;
        default = null;
        example = ["hyprctl" "dispatch" "submap" "reset"];
        description = "Command to run when a matching window loses focus. First element is the binary, the rest are args.";
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
          rules = lib.mkOption {
            type = lib.types.listOf ruleType;
            default = [];
            description = ''
              Window hook rules. Each entry matches windows by class and/or title
              (both are regexes, AND-ed) and runs a command on lifecycle events.
              Each command is a list where the first element is the binary and the rest are args.
            '';
            example = [
              {
                class      = "^gamescope$";
                title      = "Counter-Strike 2";
                on_focus   = ["hyprctl" "dispatch" "submap" "gaming"];
                on_unfocus = ["hyprctl" "dispatch" "submap" "reset"];
              }
            ];
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprhook.enable && hyprhookModuleAvailable) {
    services.hyprhook = {
      enable = true;
      rules = cfg.hyprhook.rules;
    };
  };
}
