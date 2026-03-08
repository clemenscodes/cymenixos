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
    overlays = [
      inputs.claude.overlays.default
      inputs.codex.overlays.default
    ];
  };
  jsonFormat = pkgs.formats.json {};
  mcpServers = {
    nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
    github = {
      command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
      args = ["stdio"];
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = ''''${GH_TOKEN}'';
      };
    };
    playwright = {
      command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
    };
  };
  claude = pkgs.stdenv.mkDerivation {
    inherit (pkgs.claude-code) pname version;
    dontUnpack = true;
    nativeBuildInputs = with pkgs; [makeBinaryWrapper];
    installPhase = ''
      mkdir -p $out/bin
      makeBinaryWrapper ${pkgs.claude-code}/bin/claude $out/bin/claude \
        --set CLAUDE_CONFIG_DIR /home/${user}/.config/claude \
        --set CLAUDE_PEON_DIR /home/${user}/.config/claude/hooks/peon-ping \
        "--append-flags" \
        "--mcp-config ${jsonFormat.generate "claude-code-mcp-config.json" {inherit mcpServers;}}"
    '';
  };
  codex = pkgs.stdenv.mkDerivation {
    inherit (pkgs.codex) pname version;
    dontUnpack = true;
    nativeBuildInputs = with pkgs; [makeBinaryWrapper];
    installPhase = ''
      mkdir -p $out/bin
      makeBinaryWrapper ${pkgs.codex}/bin/codex $out/bin/codex \
        --set CODEX_HOME /home/${user}/.config/codex \
        --set CLAUDE_PEON_DIR /home/${user}/.config/claude/hooks/peon-ping
    '';
  };
  claude-monitor = pkgs.stdenv.mkDerivation {
    inherit (pkgs.claude-monitor) pname version;
    dontUnpack = true;
    nativeBuildInputs = with pkgs; [makeWrapper];
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.claude-monitor}/bin/claude-monitor $out/bin/claude-monitor \
        --set CLAUDE_CONFIG_DIR /home/${user}/.config/claude \
        --set CLAUDE_PEON_DIR /home/${user}/.config/claude/hooks/peon-ping
    '';
  };
  peon = inputs.peon-ping.packages.${pkgs.system}.default;
  peonsh = pkgs.stdenv.mkDerivation {
    inherit (peon) pname version;
    dontUnpack = true;
    nativeBuildInputs = with pkgs; [makeWrapper];
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${peon}/bin/peon-codex-adapter $out/bin/peon-codex-adapter \
        --set CODEX_HOME /home/${user}/.config/codex \
        --set CLAUDE_CONFIG_DIR /home/${user}/.config/claude \
        --set CLAUDE_PEON_DIR /home/${user}/.config/claude/hooks/peon-ping
      makeWrapper ${peon}/bin/peon $out/bin/peon \
        --set CLAUDE_CONFIG_DIR /home/${user}/.config/claude \
        --set CLAUDE_PEON_DIR /home/${user}/.config/claude/hooks/peon-ping
      makeWrapper ${peon}/bin/hook-handle-use $out/bin/hook-handle-use \
        --set CLAUDE_CONFIG_DIR /home/${user}/.config/claude \
        --set CLAUDE_PEON_DIR /home/${user}/.config/claude/hooks/peon-ping
    '';
  };
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
          programs = {
            mcp = {
              enable = true;
              servers = mcpServers;
            };
            opencode = {
              enable = true;
              enableMcpIntegration = true;
            };
            claude-code = {
            };
            codex = {
              enable = true;
              package = codex;
              settings = {
                model = "gpt-5.3-codex";
                model_reasoning_effort = "xhigh";
                notify = ["${peonsh}/bin/peon-codex-adapter"];
                projects = {
                  "/home/${user}/.local/src" = {
                    trust_level = "trusted";
                  };
                };
              };
            };
          };
          home = {
            packages = [claude codex peonsh claude-monitor];
            persistence = lib.mkIf (config.modules.boot.enable) {
              "${persistPath}" = {
                directories = [".config/claude" ".config/codex"];
              };
            };
            file = {
              ".config/claude/hooks/peon-ping/peon.sh" = {
                source = "${peonsh}/bin/peon";
              };
              ".config/claude/hooks/peon-ping/skills" = {
                source = "${peon}/share/peon-ping/skills";
                recursive = true;
              };
              ".config/claude/hooks/peon-ping/packs" = {
                source = packs;
                recursive = true;
              };
              ".config/claude/hooks/peon-ping/config.json" = {
                source = jsonFormat.generate "peon-ping-config" {
                  default_pack = "peasant";
                  volume = 0.7;
                  enabled = true;
                  desktop_notifications = false;
                  categories = {
                    "session.start" = true;
                    "task.complete" = true;
                    "task.error" = false;
                    "input.required" = true;
                    "resource.limit" = true;
                    "user.spam" = true;
                  };
                };
              };
              ".config/claude/settings.json" = {
                source = jsonFormat.generate "claude-code-settings.json" {
                  "$schema" = "https://json.schemastore.org/claude-code-settings.json";
                  hooks = {
                    SessionStart = [
                      {
                        matcher = "";
                        hooks = [
                          {
                            type = "command";
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/hook-handle-use";
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
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/peon";
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
                            command = "${peonsh}/bin/peon";
                            timeout = 10;
                            async = true;
                          }
                        ];
                      }
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
