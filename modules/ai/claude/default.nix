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
            claude-code = {
              enable = true;
              hooks = {
                "peon-ping/peon.sh" = ''
                  #!/usr/bin/env bash

                  echo "Test"
                '';
                "peon-ping/config.json" = ''
                  {}
                '';
              };
              settings = {
                hooks = {
                  SessionStart = [
                    {
                      matcher = "";
                      hooks = [
                        {
                          type = "command";
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/scripts/hook-handle-use.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
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
                          command = "/home/clemens/.claude/hooks/peon-ping/peon.sh";
                          timeout = 10;
                          async = true;
                        }
                      ];
                    }
                  ];
                };
              };
              skills = {
                peon-ping-config = ''
                  ---
                  name: peon-ping-config
                  description: Update peon-ping configuration — volume, pack rotation, categories, active pack, and other settings. Use when user wants to change peon-ping settings like volume, enable round-robin, add packs to rotation, toggle sound categories, or adjust any config.
                  user_invocable: false
                  ---

                  # peon-ping-config

                  Update peon-ping configuration settings.

                  ## Config location

                  The config file is at `''${CLAUDE_CONFIG_DIR:-''$HOME/.claude}/hooks/peon-ping/config.json`.

                  ## Available settings

                  - **volume** (number, 0.0–1.0): Sound volume
                  - **active_pack** (string): Current sound pack name (e.g. `"peon"`, `"sc_kerrigan"`, `"glados"`)
                  - **enabled** (boolean): Master on/off switch
                  - **pack_rotation** (array of strings): List of packs to rotate through per session. Empty `[]` uses `active_pack` only.
                  - **pack_rotation_mode** (string): `"random"` (default) picks a random pack each session. `"round-robin"` cycles through in order. `"agentskill"` uses explicit per-session assignments from `/peon-ping-use`; invalid or missing packs fall back to `active_pack` and the stale assignment is removed.
                  - **categories** (object): Toggle individual CESP sound categories:
                    - `session.start`, `task.acknowledge`, `task.complete`, `task.error`, `input.required`, `resource.limit`, `user.spam` — each a boolean
                  - **annoyed_threshold** (number): How many rapid prompts trigger user.spam sounds
                  - **annoyed_window_seconds** (number): Time window for the annoyed threshold
                  - **silent_window_seconds** (number): Suppress task.complete sounds for tasks shorter than this many seconds
                  - **session_ttl_days** (number, default: 7): Expire stale per-session pack assignments older than N days (when using agentskill mode)
                  - **desktop_notifications** (boolean): Toggle notification popups independently from sounds (default: `true`)
                  - **use_sound_effects_device** (boolean): Route audio through macOS Sound Effects device (`true`) or default output via afplay (`false`). Only affects macOS. Default: `true`

                  ## How to update

                  1. Read the config file using the Read tool
                  2. Edit the relevant field(s) using the Edit tool
                  3. Confirm the change to the user

                  ## Common Configuration Examples

                  ### Disable desktop notification popups but keep sounds

                  **User request:** "Disable desktop notifications"

                  **Action:**
                  Set `desktop_notifications: false` in config

                  **Result:**
                  - ✅ Sounds continue playing (voice reminders)
                  - ❌ Desktop notification popups suppressed
                  - ✅ Mobile notifications unaffected (separate toggle)

                  **Alternative CLI command:**
                  ```bash
                  peon notifications off
                  # or
                  peon popups off
                  ```

                  ### Adjust volume

                  **User request:** "Set volume to 30%"

                  **Action:**
                  Set `volume: 0.3` in config

                  ### Enable round-robin pack rotation

                  **User request:** "Enable round-robin pack rotation with peon and glados"

                  **Action:**
                  Set:
                  ```json
                  {
                    "pack_rotation": ["peon", "glados"],
                    "pack_rotation_mode": "round-robin"
                  }
                  ```

                  ## Directory pack bindings

                  Permanently associate a sound pack with a working directory so every session in that directory uses the right pack automatically. Uses the `path_rules` config key (array of `{ "pattern": "<glob>", "pack": "<name>" }` objects).

                  ### CLI commands

                  ```bash
                  # Bind a pack to the current directory
                  peon packs bind <pack>
                  # e.g. peon packs bind glados
                  # → bound glados to /Users/dan/Frontend

                  # Bind with a custom glob pattern (matches any dir with that name)
                  peon packs bind <pack> --pattern "*/Frontend/*"

                  # Auto-download a missing pack and bind it
                  peon packs bind <pack> --install

                  # Remove binding for the current directory
                  peon packs unbind

                  # Remove a specific pattern binding
                  peon packs unbind --pattern "*/Frontend/*"

                  # List all bindings (* marks rules matching current directory)
                  peon packs bindings
                  ```

                  ### Manual config

                  The `path_rules` array in `config.json` can also be edited directly:

                  ```json
                  {
                    "path_rules": [
                      { "pattern": "/Users/dan/Frontend/*", "pack": "glados" },
                      { "pattern": "*/backend/*", "pack": "sc_kerrigan" }
                    ]
                  }
                  ```

                  Patterns use Python `fnmatch` glob syntax. First matching rule wins. Path rules override `default_pack` and `pack_rotation` but are overridden by `session_override` (agentskill) assignments.

                  ## List available packs

                  To show available packs, run:

                  ```bash
                  bash "''${CLAUDE_CONFIG_DIR:-''$HOME/.claude}"/hooks/peon-ping/peon.sh packs list
                  ```
                '';
                peon-ping-log = ''
                  ---
                  name: peon-ping-log
                  description: Log exercise reps for the Peon Trainer. Use when user says they did pushups, squats, or wants to log reps. Examples - "/peon-ping-log 25 pushups", "/peon-ping-log 30 squats", "log 50 pushups".
                  user_invocable: true
                  ---

                  # peon-ping-log

                  Log exercise reps for the Peon Trainer.

                  ## Usage

                  The user provides a number and exercise type. Run the following command using the Bash tool:

                  ```bash
                  bash ~/.claude/hooks/peon-ping/peon.sh trainer log <count> <exercise>
                  ```

                  Where:
                  - `<count>` is the number of reps (e.g. `25`)
                  - `<exercise>` is `pushups` or `squats`

                  ### Examples

                  ```bash
                  bash ~/.claude/hooks/peon-ping/peon.sh trainer log 25 pushups
                  bash ~/.claude/hooks/peon-ping/peon.sh trainer log 30 squats
                  ```

                  Report the output to the user. The command will print the updated rep count and play a trainer voice line.

                  ## If trainer is not enabled

                  If the output says trainer is not enabled, tell the user to run `/peon-ping-toggle` or `peon trainer on` first.

                  ## Check status

                  If the user asks for their progress after logging, also run:

                  ```bash
                  bash ~/.claude/hooks/peon-ping/peon.sh trainer status
                  ```
                '';
                peon-ping-toggle = ''
                  ---
                  name: peon-ping-toggle
                  description: Toggle peon-ping sound notifications on/off. Use when user wants to mute, unmute, pause, or resume peon sounds during a Claude Code session. Also handles config changes like volume, pack rotation, categories — any peon-ping setting.
                  user_invocable: true
                  ---

                  # peon-ping-toggle

                  Toggle peon-ping sounds on or off. Also handles any peon-ping configuration changes.

                  ## Toggle sounds

                  On Unix, run the following command using the Bash tool:

                  ```bash
                  bash "''${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/hooks/peon-ping/peon.sh toggle
                  ```

                  On Windows, use the PowerShell tool:
                  ```powershell
                  $claudeDir = $env:CLAUDE_CONFIG_DIR
                  if (-not $claudeDir -or $claudeDir -eq "") {
                    $claudeDir = Join-Path $HOME ".claude"
                  }
                  & (Join-Path $claudeDir "hooks/peon-ping/peon.ps1") toggle
                  ```

                  Report the output to the user. The command will print either:
                  - `peon-ping: sounds paused` — sounds are now muted
                  - `peon-ping: sounds resumed` — sounds are now active

                  ## What This Toggles

                  This command toggles the **master audio switch** (`enabled` config). When disabled:
                  - ❌ Sounds stop playing
                  - ❌ Desktop notifications also stop (they require sounds to be enabled)
                  - ❌ Mobile notifications also stop

                  **For notification-only control**, use `/peon-ping-config` to set `desktop_notifications: false`. This keeps sounds playing while suppressing desktop popups.

                  ## Examples

                  "Mute peon-ping completely" → Sets `enabled: false`
                  "Just disable the popups but keep sounds" → Sets `desktop_notifications: false` (use `/peon-ping-config` instead)

                  ## Configuration changes

                  For any other peon-ping setting changes (volume, pack rotation, categories, active pack, etc.), use the `peon-ping-config` skill.
                '';
                peon-ping-use = ''
                  ---
                  name: peon-ping-use
                  description: Set which voice pack (character voice) plays for the current chat session. Automatically enables agentskill rotation mode if not already set. Use when user wants a specific character voice like GLaDOS, Peon, or Kerrigan for this conversation.
                  user_invocable: true
                  license: MIT
                  metadata:
                    author: PeonPing
                    version: "1.0"
                  ---

                  # peon-ping-use

                  Set which voice pack (character voice) plays for the current chat session.

                  ## How it works

                  When the user types `/peon-ping-use <packname>`, a **beforeSubmitPrompt hook** intercepts the command before it reaches the model and handles it instantly:

                  1. Validates the requested pack exists
                  2. Enables `agentskill` rotation mode in config.json
                  3. Maps the current session ID to the requested pack in .state.json
                  4. Returns immediate confirmation (zero tokens used)

                  When the hook blocks the message, Cursor keeps your cursor in the input field so you can type your next message right away.

                  The hook scripts (`scripts/hook-handle-use.sh` and `scripts/hook-handle-use.ps1`) do all the work - this SKILL.md file exists solely for discoverability in the `/` command autocomplete menu.

                  ## Usage

                  Users can invoke this by typing:

                  ```
                  /peon-ping-use peasant
                  /peon-ping-use glados
                  /peon-ping-use sc_kerrigan
                  ```

                  If the hook is not installed or fails, you can fallback to manual execution by following the instructions below.

                  ## Manual fallback (if hook fails)

                  If for some reason the hook doesn't intercept the command, follow these steps:

                  ### 1. Parse the pack name

                  Extract the pack name from the user's request. Common pack names:
                  - `peon` — Warcraft Peon
                  - `glados` — Portal's GLaDOS
                  - `sc_kerrigan` — StarCraft Kerrigan
                  - `peasant` — Warcraft Peasant
                  - `hk47` — Star Wars HK-47

                  ### 2. List available packs

                  Run this command to see installed packs:

                  ```bash
                  bash "''${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/hooks/peon-ping/peon.sh packs list
                  ```

                  Parse the output to verify the requested pack exists.

                  ### 3. Get session ID

                  The session ID is available in the environment variable `CLAUDE_SESSION_ID`. Read it:

                  ```bash
                  echo "$CLAUDE_SESSION_ID"
                  ```

                  **If empty (Cursor users):** Use `"default"` as the key in `session_packs`. This applies the pack to all sessions without explicit assignment. Add `session_packs["default"] = {"pack": "PACK_NAME", "last_used": UNIX_TIMESTAMP}`.

                  ### 4. Update config to enable agentskill mode

                  Read the config file:

                  ```bash
                  cat "''${CLAUDE_CONFIG_DIR:-''$HOME/.claude}"/hooks/peon-ping/config.json
                  ```

                  **Required:** Set `pack_rotation_mode` to `"agentskill"`. The pack must exist in the packs directory; if the assigned pack is missing or invalid, peon-ping falls back to `active_pack` and removes the stale assignment. The hook also adds the pack to `pack_rotation` (manual fallback can do the same).

                  Example config after setup:

                  ```json
                  "pack_rotation_mode": "agentskill",
                  "pack_rotation": ["peasant", "peon", "ra2_kirov"]
                  ```

                  If `pack_rotation_mode` is `"random"` or `"round-robin"`, change it to `"agentskill"`. If the requested pack is not in `pack_rotation`, add it.

                  ### 5. Update state to assign pack to this session

                  Read the state file:

                  ```bash
                  cat "''${CLAUDE_CONFIG_DIR:-''$HOME/.claude}"/hooks/peon-ping/.state.json
                  ```

                  Update the `session_packs` object to map this session to the requested pack. If `session_packs` doesn't exist, create it:

                  ```json
                  {
                    "session_packs": {
                      "SESSION_ID_HERE": "pack_name_here"
                    }
                  }
                  ```

                  Use StrReplace or edit the JSON to add/update the entry:

                  - If `session_packs` exists: add or update the session ID key
                  - If `session_packs` doesn't exist: add it after the opening brace

                  ### 6. Confirm to user

                  Report success with a message like:

                  ```
                  Voice set to [PACK_NAME] for this session
                     Rotation mode: agentskill
                  ```

                  ## Error handling

                  - **Pack not found**: List available packs and ask user to choose one
                  - **No session ID**: Inform user this feature requires Claude Code
                  - **File read/write errors**: Report the error and suggest manual config editing

                  ## Example interaction

                  ```
                  User: Use GLaDOS voice for this chat
                  Assistant: [Lists packs to verify glados exists]
                  Assistant: [Gets session ID]
                  Assistant: [Updates config.json to set pack_rotation_mode: "agentskill"]
                  Assistant: [Updates .state.json to set session_packs[session_id] = "glados"]
                  Assistant: Voice set to GLaDOS for this session
                             Rotation mode: agentskill
                  ```

                  ## Cursor compatibility note

                  Cursor doesn't expose session IDs. Use `session_packs["default"]` instead: when doing the manual fallback, add `"default": {"pack": "peasant", "last_used": 0}` to `session_packs`. This applies the voice to sessions without explicit assignment (including Cursor chats).

                  ## Reset to default

                  To stop using a specific pack for this session, remove the session ID from `session_packs` in `.state.json`, or change `pack_rotation_mode` back to `"random"` or `"round-robin"`.
                '';
              };
            };
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
