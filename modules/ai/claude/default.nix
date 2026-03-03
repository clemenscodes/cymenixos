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
  inherit (config.modules.boot.impermanence) persistPath;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["claude-code"];
    };
    overlays = [inputs.claude.overlays.default];
  };
in {
  options = {
    modules = {
      ai = {
        claude = {
          enable = lib.mkEnableOption "Enable Claude Code";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.claude.enable) {
    home-manager = {
      users = {
        ${config.modules.users.user} = {
          imports = [inputs.peon-ping.homeManagerModules.default];
          home = {
            packages = with pkgs; [claude-code];
            persistence = lib.mkIf (config.modules.boot.enable) {
              "${persistPath}" = {
                directories = [".openpeon" ".claude"];
                files = [".claude.json"];
              };
            };
          };
          programs = {
            peon-ping = {
              enable = true;
              package = inputs.peon-ping.packages.${pkgs.system}.default;
              settings = {
                default_pack = "peasant";
                volume = 0.7;
                enabled = true;
                desktop_notifications = true;
                enableZshIntegration = true;
                categories = {
                  "session.start" = true;
                  "task.complete" = true;
                  "task.error" = true;
                  "input.required" = true;
                  "resource.limit" = true;
                  "user.spam" = true;
                };
              };
            };
          };
        };
      };
    };
  };
}
