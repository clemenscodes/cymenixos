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
        type = lib.types.listOf (lib.types.nonEmptyListOf lib.types.str);
        default = [];
        example = [["obs-cli" "start-recording"]];
        description = "Commands to run when a matching window is created. Each command is an argv list.";
      };
      on_close = lib.mkOption {
        type = lib.types.listOf (lib.types.nonEmptyListOf lib.types.str);
        default = [];
        example = [["obs-cli" "stop-recording"]];
        description = "Commands to run when a matching window is destroyed. Each command is an argv list.";
      };
      on_focus = lib.mkOption {
        type = lib.types.listOf (lib.types.nonEmptyListOf lib.types.str);
        default = [];
        example = [["hyprctl" "dispatch" "submap" "gaming"]];
        description = "Commands to run when a matching window gains focus. Each command is an argv list.";
      };
      on_unfocus = lib.mkOption {
        type = lib.types.listOf (lib.types.nonEmptyListOf lib.types.str);
        default = [];
        example = [["hyprctl" "dispatch" "submap" "reset"]];
        description = "Commands to run when a matching window loses focus. Each command is an argv list.";
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
              (both are regexes, AND-ed) and runs commands on lifecycle events.
              Each command is an argv list: ["executable" "arg1" "arg2" ...].
            '';
            example = lib.literalExpression ''
              [
                {
                  class      = "^gamescope$";
                  title      = "Counter-Strike 2";
                  on_focus   = [ ["/run/current-system/sw/bin/hyprctl" "dispatch" "submap" "gaming"] ];
                  on_unfocus = [ ["/run/current-system/sw/bin/hyprctl" "dispatch" "submap" "reset"] ];
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
      rules = cfg.hyprhook.rules;
    };
  };
}
