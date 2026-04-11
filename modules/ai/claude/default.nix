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
  mcpServers = config.modules.ai.mcp.servers;

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
        "--dangerously-skip-permissions --mcp-config ${
        jsonFormat.generate "claude-code-mcp-config.json" {inherit mcpServers;}
      }"
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
  peon = inputs.peon-ping.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
  agents = pkgs.fetchFromGitHub {
    owner = "msitarzewski";
    repo = "agency-agents";
    rev = "746efaa6b4e8a0ea15cf9c7fe6f5b5425ed1ba8e";
    hash = "sha256-YPC8QXrq2uv6iM3z7MuZ4Zi7XMkTVTprYnq+VCywGzc=";
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
                model_reasoning_effort = "low";
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
            packages = [
              claude
              codex
              peonsh
              claude-monitor
            ];
            persistence = lib.mkIf (config.modules.boot.enable) {
              "${persistPath}" = {
                directories = [
                  ".config/claude"
                  ".config/codex"
                ];
              };
            };
            file = {
              ".config/claude/agents" = {
                source = agents;
                recursive = true;
              };
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
              ".config/claude/CLAUDE.md" = {
                text = ''
                  # NixOS System

                  This system runs NixOS. Most tools (`python`, `jq`, `curl`, `node`, etc.) are NOT in PATH.

                  **Always use `nix run nixpkgs#<pkg>` — never try a bare binary first.**

                  ```
                  nix run nixpkgs#jq -- -r '.key' file.json
                  nix run nixpkgs#python3 -- script.py
                  nix shell nixpkgs#jq nixpkgs#curl   # multi-tool
                  ```

                  Use the NixOS MCP (`mcp__nixos__nix`) or `nix search nixpkgs <name>` to find package names.

                  ## System Configuration

                  The active system config is at `$FLAKE/configuration.nix`. It uses the CymenixOS module library,
                  with all options namespaced under `modules.*`.

                  To add an option: edit `$FLAKE/configuration.nix`, then rebuild:
                  ```
                  sudo nixos-rebuild switch --flake "$FLAKE#${user}"
                  ```

                  To understand available options, check the CymenixOS `api/os.nix` (system) or `api/home.nix` (home-manager).

                  ## Nix Derivations

                  **Always build and verify after writing** any Nix derivation. The task is not done until it builds:
                  ```
                  nix build --no-link --impure --expr \
                    'let pkgs = import <nixpkgs> {}; in import ./path/to/file.nix { inherit pkgs; /* required args */ }'
                  ```

                  **In multi-line Nix strings**, `''${...}` is Nix antiquotation — shell variables with braces
                  like `''${h}` will cause "undefined variable" errors. Use bare `$h` (no braces) or escape with `''''`.

                  **Grep for unintended antiquotations** before finishing:
                  ```
                  grep -n '\''${' file.nix
                  ```

                  **No underscore separators in integer literals** — `5_000_000` is invalid Nix; use `5000000`.

                  ## Rust Standards

                  These are the minimum standards for publishable or mergeable Rust code.

                  ### Naming

                  - All constants must be named. No bare literals with unexplained meaning (`0`, `4`, `0xDA`, `1000`). Every magic value gets a `const` whose name states what it represents.
                  - Struct fields must be named for their semantic meaning, never for their position. `param0`, `param3`, `magic_lo` are forbidden — they are C-style positional names that destroy readability.
                  - Variable names must be full words describing what the value is, not abbreviations (`kb`, `n`, `resp`, `p`).
                  - Follow standard Rust conventions: `PascalCase` for types and enum variants, `snake_case` for functions and variables, `SCREAMING_SNAKE_CASE` for constants.

                  ### Types and structs

                  - Model everything with structs. If you are returning or passing multiple related values, define a named struct — never a tuple.
                  - Never use tuple structs. They provide no semantic benefit over a struct with named fields and force callers to use positional access.
                  - No `pub` fields. Expose data via `pub` getter methods returning shared references (`&T`) or copies (`T: Copy`).
                  - Use traits to model behaviour: `Display`, `From`, `TryFrom`, `Serialize`, etc. Do not write free functions that duplicate what a trait impl would express.
                  - Enums must be either complete (full variant surface, with `#[allow(dead_code)]` accepted on the whole enum) or minimal (only variants the code uses, no `#[allow(dead_code)]`). Never have a partial enum with `#[allow(dead_code)]`.

                  ### No type casts or type indicators

                  - `as T` casts at call sites are forbidden. If a cast is needed, the type design is wrong — fix the types so the cast disappears.
                  - Type indicators on literals (`0u8`, `1usize`) are forbidden for the same reason. If the compiler cannot infer the type, the API is wrong.
                  - Lossless conversions use `From`/`Into`. The one accepted use of `as u8` is inside a `From<EnumType> for u8` impl for `#[repr(u8)]` enums — isolated in one place.
                  - Avoid `Some(&value)` pattern matches against primitives. Use `.copied()` to turn `Option<&T>` into `Option<T>` first.

                  ### Struct instantiation and function calls

                  - Never instantiate a struct inline as an argument or inside `Ok(...)`. Always bind to a named variable first, then pass the variable.
                  - Function calls stay on one line. Multi-line argument lists are a sign the call is too complex or needs refactoring.
                  - Always `use` types before using them. Never qualify types at call sites (`keyboard::ProfileNumber`) when an import would make it `ProfileNumber`.
                  - Inside an `impl` block, always use `Self` instead of the struct name when constructing or returning the type (e.g. `Self { field }` not `MyStruct { field }`).
                  - Every struct that is constructed outside its own `impl` must expose a `new()` constructor. Inline `StructName { .. }` literals at call sites are forbidden outside the struct's own impl.

                  ### Code organisation

                  - No section-divider comments (`// === Foo ===`, `// --- helpers ---`). If a file needs sections, split it into modules.
                  - Scope functions to their natural owner. A function that operates on or belongs to a type is an associated function or method on that type, not a free function.
                  - No backwards-compatibility shims, unused `_variables`, or removed-but-kept code. Delete dead code entirely.

                  ### Formatting and linting

                  - All Rust code must pass `rustfmt` and `cargo clippy --all-targets -- -D warnings` before it is considered done.
                  - Run both after every edit. A task is not complete until both pass cleanly.
                '';
              };
              ".config/claude/settings.json" = {
                source = jsonFormat.generate "claude-code-settings.json" {
                  "$schema" = "https://json.schemastore.org/claude-code-settings.json";
                  skipDangerousModePermissionPrompt = true;
                  effortLevel = "low";
                  permissions = {
                    defaultMode = "bypassPermissions";
                  };
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
