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
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["claude-code"];
    };
    overlays = [inputs.claude.overlays.default];
  };
  claude = pkgs.stdenv.mkDerivation {
    inherit (pkgs.claude-code) pname version;
    nativeBuildInputs = with pkgs; [makeBinaryWrapper];
    installPhase = ''
      mkdir -p $out/bin
      makeBinaryWrapper ${pkgs.claude-code}/bin/claude $out/bin/claude \
        --set HOME /home/${user}/.config/claude
    '';
  };
  peon = inputs.peon-ping.packages.${pkgs.system}.default;
  packs = pkgs.fetchFromGitHub {
    owner = "PeonPing";
    repo = "og-packs";
    rev = "v1.3.0";
    hash = "sha256-zrpdEQFWWeX0V2nGRU8MYLB8HnoSpP+kFij+A5Ymj74=";
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
        ${user} = {
          imports = [inputs.peon-ping.homeManagerModules.default];
          home = {
            file = {
              ".claude/hooks/peon-ping/peon.sh" = {
                source = "${peon}/bin/peon";
              };
              ".claude/hooks/peon-ping/config.json" = {
                source = (pkgs.formats.json {}).generate "peon-ping-config" config.home-manager.users.${user}.programs.peon-ping.settings;
              };
              ".claude/hooks/peon-ping/skills" = {
                source = "${peon}/share/peon-ping/skills";
                recursive = true;
              };
              ".openpeon/packs" = {
                source = packs;
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
              package = claude;
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
