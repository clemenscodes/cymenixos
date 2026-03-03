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
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["claude-code"];
    };
    overlays = [inputs.claude.overlays.default];
  };
  peon = inputs.peon-ping.packages.${pkgs.system}.default;
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
            file = {
              ".claude/hooks/peon-ping/skills" = {
                source = "${peon}/share/peon-ping/skills";
                recursive = true;
              };
            };
            persistence = lib.mkIf (config.modules.boot.enable) {
              "${persistPath}" = {
                directories = [".openpeon" ".claude"];
                files = [".claude.json"];
              };
            };
          };
          programs = {
            claude-code = {
              enable = true;
              package = pkgs.claude-code;
              settings = {
                hooks = {
                  SessionStart = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                        }
                      ];
                    }
                  ];
                  SessionEnd = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                  SubagentStart = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                  UserPromptSubmit = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/hook-handle-use";
                          timeout = 5;
                        }
                      ];
                    }
                  ];
                  Stop = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                  Notification = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                  PermissionRequest = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                  PostToolUseFailure = [
                    {
                      matcher = "Bash";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                  PreCompact = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "${peon}/bin/peon";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                };
              };
            };
            peon-ping = {
              enable = true;
              package = inputs.peon-ping.packages.${pkgs.system}.default;
              enableZshIntegration = true;
              settings = {
                default_pack = "peasant";
                volume = 0.7;
                enabled = true;
                desktop_notifications = true;
                installPacks = ["peon" "peasant"];
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
