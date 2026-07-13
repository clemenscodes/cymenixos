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
  # obra/superpowers v6.0.3 — a skills library for Claude Code (TDD, debugging,
  # planning, code-review workflows). Upstream ships it as a plugin, but the
  # plugin registry (plugins/installed_plugins.json) is mutable runtime state,
  # so we install its skills declaratively as flat personal skills instead.
  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "896224c4b1879920ab573417e68fd51d2ccc9072"; # v6.0.3
    hash = "sha256-+lT2a/qq0SF4k0PgnEDKiuidVlZX2p0vEso4d/5T1os=";
  };
  # Skill cross-references use the `superpowers:` plugin namespace (e.g.
  # `superpowers:test-driven-development`). Strip the prefix so they resolve as
  # flat personal skills under ~/.config/claude/skills.
  superpowers-skills = pkgs.runCommand "superpowers-skills" {} ''
    cp -r ${superpowers}/skills $out
    chmod -R u+w $out
    find $out -name '*.md' -exec sed -i 's/superpowers:\([a-z]\)/\1/g' {} +
  '';
  # Skill directories shipped by superpowers v6.0.3 (one SKILL.md each).
  superpowersSkillNames = [
    "brainstorming"
    "dispatching-parallel-agents"
    "executing-plans"
    "finishing-a-development-branch"
    "receiving-code-review"
    "requesting-code-review"
    "subagent-driven-development"
    "systematic-debugging"
    "test-driven-development"
    "using-git-worktrees"
    "using-superpowers"
    "verification-before-completion"
    "writing-plans"
    "writing-skills"
  ];
  superpowersSkillFiles = lib.listToAttrs (map (name:
    lib.nameValuePair ".config/claude/skills/${name}" {
      source = "${superpowers-skills}/${name}";
    })
  superpowersSkillNames);
  # Replicates superpowers' own SessionStart hook: injects the
  # using-superpowers bootstrap skill so skill usage is active from the first
  # message of every session.
  superpowers-session-start = pkgs.writeShellScript "superpowers-session-start" ''
    ${pkgs.jq}/bin/jq -n --rawfile sp ${superpowers-skills}/using-superpowers/SKILL.md \
      '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: ("<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n" + $sp + "\n</EXTREMELY_IMPORTANT>")}}'
  '';
  # Globaler PreToolUse(Bash)-Hook: verhindert, dass ein Agent das
  # touch-pflichtige Commit-Signing umgeht. Der eigentliche Schutz ist der
  # YubiKey-Touch am Signaturschluessel (Signing ohne physische Anwesenheit
  # unmoeglich); dieser Hook schliesst nur den verbleibenden Weg "einfach
  # unsigniert bzw. mit uebersprungenem Verify committen/pushen". Weil er in
  # der globalen settings.json haengt, greift er in JEDER Session und jedem
  # Repo, unabhaengig davon, wo Claude gestartet wurde (also auch in pam).
  block-unsigned-commit = pkgs.writeShellApplication {
    name = "block-unsigned-commit";
    runtimeInputs = [pkgs.jq pkgs.gnugrep];
    text = ''
      cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null || true)"
      [ -n "$cmd" ] || exit 0

      reason=""
      if printf '%s' "$cmd" | grep -qE -- '--no-gpg-sign'; then
        reason="--no-gpg-sign"
      elif printf '%s' "$cmd" | grep -qE 'commit\.gpgsign[[:space:]]*=[[:space:]]*(false|no|0)\b'; then
        reason="-c commit.gpgsign=false"
      elif printf '%s' "$cmd" | grep -qE 'commit\.gpgsign[[:space:]]+(false|no|0)\b'; then
        reason="git config commit.gpgsign false"
      elif printf '%s' "$cmd" | grep -qE -- '--unset[[:space:]]+commit\.gpgsign'; then
        reason="--unset commit.gpgsign"
      elif printf '%s' "$cmd" | grep -qE -- '--no-verify'; then
        reason="--no-verify (ueberspringt den pre-push Signatur-Check)"
      elif printf '%s' "$cmd" | grep -qiE 'core\.hookspath[[:space:]]*[= ]'; then
        reason="core.hooksPath override (deaktiviert den pre-push Hook)"
      fi

      [ -n "$reason" ] || exit 0

      {
        echo "DENIED: dieser Befehl versucht, das Commit-Signing zu umgehen ($reason)."
        echo "Signieren verlangt einen physischen YubiKey-Touch, Agents committen hier"
        echo "nicht. Wenn Signing gerade fehlgeschlagen ist (YubiKey nicht gesteckt,"
        echo "Touch-Timeout, falsche PIN): das heisst STOP und den Menschen informieren,"
        echo "es ist KEINE Erlaubnis, Signing zu deaktivieren oder zu ueberspringen."
      } >&2
      exit 2
    '';
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
              enableMcpIntegration = true;
              package = codex;
              settings = {
                model = "gpt-5.5-codex";
                model_reasoning_effort = "xhigh";
                approval_policy = "never";
                sandbox_mode = "danger-full-access";
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
            file =
              superpowersSkillFiles
              // {
                ".config/claude/agents" = {
                  source = agents;
                  recursive = true;
                };
                ".config/codex/skills/karpathy/SKILL.md" = {
                  text = ''
                    ---
                    name: karpathy
                    description: Karpathy-inspired best practices for LLM coding — think before coding, simplicity first, surgical changes, goal-driven execution. Activates behavioral guidelines that reduce common LLM coding mistakes.
                    user_invocable: false
                    ---

                    # Karpathy Coding Principles

                    Behavioral guidelines to reduce common LLM coding mistakes.

                    **Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

                    ## 1. Think Before Coding

                    **Don't assume. Don't hide confusion. Surface tradeoffs.**

                    Before implementing:
                    - State your assumptions explicitly. If uncertain, ask.
                    - If multiple interpretations exist, present them - don't pick silently.
                    - If a simpler approach exists, say so. Push back when warranted.
                    - If something is unclear, stop. Name what's confusing. Ask.

                    ## 2. Simplicity First

                    **Minimum code that solves the problem. Nothing speculative.**

                    - No features beyond what was asked.
                    - No abstractions for single-use code.
                    - No "flexibility" or "configurability" that wasn't requested.
                    - No error handling for impossible scenarios.
                    - If you write 200 lines and it could be 50, rewrite it.

                    Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

                    ## 3. Surgical Changes

                    **Touch only what you must. Clean up only your own mess.**

                    When editing existing code:
                    - Don't "improve" adjacent code, comments, or formatting.
                    - Don't refactor things that aren't broken.
                    - Match existing style, even if you'd do it differently.
                    - If you notice unrelated dead code, mention it - don't delete it.

                    When your changes create orphans:
                    - Remove imports/variables/functions that YOUR changes made unused.
                    - Don't remove pre-existing dead code unless asked.

                    The test: Every changed line should trace directly to the user's request.

                    ## 4. Goal-Driven Execution

                    **Define success criteria. Loop until verified.**

                    Transform tasks into verifiable goals:
                    - "Add validation" → "Write tests for invalid inputs, then make them pass"
                    - "Fix the bug" → "Write a test that reproduces it, then make it pass"
                    - "Refactor X" → "Ensure tests pass before and after"

                    For multi-step tasks, state a brief plan first, then verify each step before proceeding.

                    Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
                  '';
                };
                ".config/claude/skills/karpathy/SKILL.md" = {
                  text = ''
                    ---
                    name: karpathy
                    description: Karpathy-inspired best practices for LLM coding — think before coding, simplicity first, surgical changes, goal-driven execution. Activates behavioral guidelines that reduce common LLM coding mistakes.
                    user_invocable: false
                    ---

                    # Karpathy Coding Principles

                    Behavioral guidelines to reduce common LLM coding mistakes.

                    **Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

                    ## 1. Think Before Coding

                    **Don't assume. Don't hide confusion. Surface tradeoffs.**

                    Before implementing:
                    - State your assumptions explicitly. If uncertain, ask.
                    - If multiple interpretations exist, present them - don't pick silently.
                    - If a simpler approach exists, say so. Push back when warranted.
                    - If something is unclear, stop. Name what's confusing. Ask.

                    ## 2. Simplicity First

                    **Minimum code that solves the problem. Nothing speculative.**

                    - No features beyond what was asked.
                    - No abstractions for single-use code.
                    - No "flexibility" or "configurability" that wasn't requested.
                    - No error handling for impossible scenarios.
                    - If you write 200 lines and it could be 50, rewrite it.

                    Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

                    ## 3. Surgical Changes

                    **Touch only what you must. Clean up only your own mess.**

                    When editing existing code:
                    - Don't "improve" adjacent code, comments, or formatting.
                    - Don't refactor things that aren't broken.
                    - Match existing style, even if you'd do it differently.
                    - If you notice unrelated dead code, mention it - don't delete it.

                    When your changes create orphans:
                    - Remove imports/variables/functions that YOUR changes made unused.
                    - Don't remove pre-existing dead code unless asked.

                    The test: Every changed line should trace directly to the user's request.

                    ## 4. Goal-Driven Execution

                    **Define success criteria. Loop until verified.**

                    Transform tasks into verifiable goals:
                    - "Add validation" → "Write tests for invalid inputs, then make them pass"
                    - "Fix the bug" → "Write a test that reproduces it, then make it pass"
                    - "Refactor X" → "Ensure tests pass before and after"

                    For multi-step tasks, state a brief plan first, then verify each step before proceeding.

                    Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
                  '';
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
                ".config/codex/AGENTS.md" = {
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

                    ## Coding Principles

                    Behavioral guidelines to reduce common LLM coding mistakes.

                    **Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

                    ### Think Before Coding

                    **Don't assume. Don't hide confusion. Surface tradeoffs.**

                    Before implementing:
                    - State your assumptions explicitly. If uncertain, ask.
                    - If multiple interpretations exist, present them - don't pick silently.
                    - If a simpler approach exists, say so. Push back when warranted.
                    - If something is unclear, stop. Name what's confusing. Ask.

                    ### Simplicity First

                    **Minimum code that solves the problem. Nothing speculative.**

                    - No features beyond what was asked.
                    - No abstractions for single-use code.
                    - No "flexibility" or "configurability" that wasn't requested.
                    - No error handling for impossible scenarios.
                    - If you write 200 lines and it could be 50, rewrite it.

                    Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

                    ### Surgical Changes

                    **Touch only what you must. Clean up only your own mess.**

                    When editing existing code:
                    - Don't "improve" adjacent code, comments, or formatting.
                    - Don't refactor things that aren't broken.
                    - Match existing style, even if you'd do it differently.
                    - If you notice unrelated dead code, mention it - don't delete it.

                    When your changes create orphans:
                    - Remove imports/variables/functions that YOUR changes made unused.
                    - Don't remove pre-existing dead code unless asked.

                    The test: Every changed line should trace directly to the user's request.

                    ### Goal-Driven Execution

                    **Define success criteria. Loop until verified.**

                    Transform tasks into verifiable goals:
                    - "Add validation" → "Write tests for invalid inputs, then make them pass"
                    - "Fix the bug" → "Write a test that reproduces it, then make it pass"
                    - "Refactor X" → "Ensure tests pass before and after"

                    For multi-step tasks, state a brief plan first, then verify each step before proceeding.

                    Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
                  '';
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

                    ## Coding Principles

                    Behavioral guidelines to reduce common LLM coding mistakes.

                    **Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

                    ### Think Before Coding

                    **Don't assume. Don't hide confusion. Surface tradeoffs.**

                    Before implementing:
                    - State your assumptions explicitly. If uncertain, ask.
                    - If multiple interpretations exist, present them - don't pick silently.
                    - If a simpler approach exists, say so. Push back when warranted.
                    - If something is unclear, stop. Name what's confusing. Ask.

                    ### Simplicity First

                    **Minimum code that solves the problem. Nothing speculative.**

                    - No features beyond what was asked.
                    - No abstractions for single-use code.
                    - No "flexibility" or "configurability" that wasn't requested.
                    - No error handling for impossible scenarios.
                    - If you write 200 lines and it could be 50, rewrite it.

                    Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

                    ### Surgical Changes

                    **Touch only what you must. Clean up only your own mess.**

                    When editing existing code:
                    - Don't "improve" adjacent code, comments, or formatting.
                    - Don't refactor things that aren't broken.
                    - Match existing style, even if you'd do it differently.
                    - If you notice unrelated dead code, mention it - don't delete it.

                    When your changes create orphans:
                    - Remove imports/variables/functions that YOUR changes made unused.
                    - Don't remove pre-existing dead code unless asked.

                    The test: Every changed line should trace directly to the user's request.

                    ### Goal-Driven Execution

                    **Define success criteria. Loop until verified.**

                    Transform tasks into verifiable goals:
                    - "Add validation" → "Write tests for invalid inputs, then make them pass"
                    - "Fix the bug" → "Write a test that reproduces it, then make it pass"
                    - "Refactor X" → "Ensure tests pass before and after"

                    For multi-step tasks, state a brief plan first, then verify each step before proceeding.

                    Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

                    ## Subagents and nested subagents

                    Make extensive use of subagents — and nested subagents (up to 5 levels deep) — at every stage to keep contexts focused: delegate non-trivial searches, investigations, and self-contained implementation tasks.

                    **The invariant: always _await_ a subagent — block on its result before doing any dependent or overlapping work.** Never end a turn with "I've launched X, I'll report back," and never start work that consumes a subagent's output before that output is in hand. (This harness exposes no per-call `foreground`/`background` flag; foreground vs background is governed by the agent type and by env config, so reach for the right call below.)

                    - **Foreground / blocking subagent (default):** `Agent({ subagent_type: "<type>", description, prompt })`; omit `subagent_type` for a fresh `general-purpose` agent. This blocks and returns the subagent's final message inline as the tool result. Optional `model`, `mode`. Prefer this for almost everything — it's the cheapest and most predictable option.
                    - **Parallel:** issue several `Agent(...)` calls in a **single message** — they run concurrently and all results return before the turn proceeds. Many-calls-in-one-message buys concurrency; it is *not* a substitute for awaiting.
                    - **Fork (inherit the whole conversation):** `Agent({ subagent_type: "fork", description, prompt })`. A fork inherits the parent's entire history, system prompt, tools, and model (any `model` override is ignored) — use it when a fresh subagent would need too much re-explaining, or to try several approaches from the same starting point. A fork runs in the **background** by design, so after launching it, block on its completion before any dependent work — don't run overlapping work alongside it. Add `isolation: "worktree"` if it edits files; a fork cannot spawn another fork.
                    - **Parallel file-mutating agents:** add `isolation: "worktree"` so concurrent agents don't clobber the checkout.
                    - **Awaiting a backgrounded agent/fork:** there is no explicit "join" call — launch it (the call returns an `agentId`), then yield the turn and do nothing overlapping; the harness re-invokes you with a `<task-notification>` carrying the final result. For several, launch all in one message and await every notification. Do not `Read`/tail the task-output `.jsonl` — it floods context.
                    - **Resume a prior subagent:** `SendMessage({ to: "<agentId>", message, summary })` continues it with full context.

                    ## Agent teams (experimental, enabled)

                    `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set, so teammate agents (`Agent({ name: "..." })`) are available in addition to subagents. Teams let teammates run independently in their own context windows and message each other directly, instead of only reporting back to you.

                    **Default to subagents, not teammates.** Reach for a team only when the work genuinely needs peer-to-peer coordination (e.g. multiple independent research angles that should compare notes, or parallel code review with distinct foci) — not as a shortcut to avoid awaiting. Known rough edges to weigh before spawning one:
                    - The "unsolicited subagent messages leak into the main context" background-isolation bug is real and applies to teammates — expect noise back in your context outside of your own turns.
                    - No `/resume` support with in-process teammates — a session restart drops them.
                    - Task status can lag (a teammate finishes but doesn't mark its task done) and shutdown can be slow (a teammate finishes current work before exiting).
                    - Teammates cannot spawn their own teammates or background subagents (no nesting beyond one level).
                    - Still **await** whatever you spawn — a team doesn't relax the "never end a turn on fire-and-forget work" rule, it just changes how the spawned work communicates back.
                  '';
                };
                ".config/claude/settings.json" = {
                  source = jsonFormat.generate "claude-code-settings.json" {
                    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
                    skipDangerousModePermissionPrompt = true;
                    effortLevel = "high";
                    env = {
                      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
                    };
                    permissions = {
                      defaultMode = "bypassPermissions";
                    };
                    hooks = {
                      PreToolUse = [
                        {
                          matcher = "Bash";
                          hooks = [
                            {
                              type = "command";
                              command = "${block-unsigned-commit}/bin/block-unsigned-commit";
                              timeout = 10;
                            }
                          ];
                        }
                      ];
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
                        {
                          matcher = "startup|clear|compact";
                          hooks = [
                            {
                              type = "command";
                              command = "${superpowers-session-start}";
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
