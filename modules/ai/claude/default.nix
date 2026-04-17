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

                  These rules are MANDATORY and absolute. Every rule applies without exception unless explicitly stated otherwise. There is exactly one correct way to write each construct. The standard: if Jon Gjengset reads this code and has nothing to improve, the task is done. Nothing less is acceptable.

                  A task is not complete until all three pass: `rustfmt` produces no changes, `cargo clippy --all-targets -- -D warnings` passes with zero warnings, and `cargo test` passes. Run all three after every single edit. Code that does not compile is not code.

                  ---

                  ### Philosophy

                  These are the governing principles. Every specific rule below derives from one of these.

                  **Make illegal states unrepresentable.** The type system is the primary correctness tool. If invalid input can be expressed as a type, the design is wrong. Every domain constraint that can be enforced statically must be enforced statically. Never validate at runtime what the compiler can enforce.

                  **Zero-cost abstractions.** Rust's abstractions compile to machine code equivalent to hand-written equivalents. Never sacrifice abstraction for performance — the language provides both. Never choose the wrong abstraction (heap allocation, dynamic dispatch) when a zero-cost equivalent exists.

                  **Explicit over implicit.** Every allocation is visible. Every conversion is visible. Every fallible operation is visible. Code that hides cost or fallibility in implicit conversions is wrong Rust.

                  **Ownership is the design.** The ownership model is not an obstacle. It is the architecture. Correct ownership means correct lifetime, correct thread safety, and correct resource cleanup. Fighting the borrow checker means the ownership design is wrong — fix the design, not the borrow checker.

                  **Fail fast with types, fail loudly at boundaries.** Invalid data never enters the system. Validate at system boundaries (user input, network, files) and convert to domain types immediately. Once inside the domain, invariants are guaranteed by the type system.

                  **Minimal surface, maximum depth.** Public APIs expose the minimum necessary. Internal complexity is hidden. Every `pub` item is a commitment that cannot be taken back without a breaking change. Every item that does not need to be public must not be public.

                  **Names are contracts.** A name communicates intent, not implementation. A function named `process` communicates nothing. A function named `validate_and_normalize_email` communicates everything. Code that names things poorly is incorrect code.

                  ---

                  ### Verification

                  Every task ends with all three of these passing. Not two. All three.

                  - `rustfmt` — run with `cargo fmt --check`. One character difference means the task is not done.
                  - `cargo clippy --all-targets -- -D warnings` — zero warnings. One warning means the task is not done.
                  - `cargo test --all` — all tests pass. A passing compiler is not a passing test suite.

                  Do not suppress warnings with `#[allow(...)]` to make clippy pass. Fix the underlying problem. The one exception: `#[allow(dead_code)]` on entire enums whose variants are part of the public API but not yet exercised in this crate. Anywhere else, delete the dead code.

                  ---

                  ### Workspace and Crate Architecture

                  **Workspace layout — flat, no exceptions:**
                  - All crates live exactly one level deep under `crates/` at the workspace root.
                  - Structure: `crates/auth/`, `crates/billing/`, `crates/notification/` — never `crates/auth/crates/inner/`.
                  - The workspace root `Cargo.toml` contains only `[workspace]`, `[workspace.dependencies]`, and `[workspace.metadata]`. Zero business logic. Zero `[lib]` or `[bin]` sections at the root.
                  - Every member crate is listed explicitly in `[workspace] members = [...]`. Glob patterns (`crates/*`) are forbidden — they silently include unintended directories.
                  - One `Cargo.lock` at the workspace root. Individual crates never have their own lock files.
                  - Shared dependency versions live in `[workspace.dependencies]`. Crate `Cargo.toml` files inherit with `{ workspace = true }`. Version numbers appear exactly once in the entire workspace.

                  **Library vs. binary — always split:**
                  - Every non-trivial project has a library crate containing all logic.
                  - The binary crate is a thin shell: argument parsing, config loading, runtime setup (tokio runtime, tracing subscriber), one call into the library, error reporting. Zero business logic.
                  - All functions that could be unit-tested independently live in the library crate.
                  - All unit tests live in the library crate.
                  - The binary crate has no tests of its own. It is tested end-to-end through integration tests.

                  **ARCHITECTURE.md — required at workspace root:**
                  - What the system does: one paragraph of plain English.
                  - Crate-level map: one line per crate — name, one-sentence responsibility, direct crate dependencies.
                  - Data flow: how data enters the system, how it is transformed, how it exits.
                  - Key invariants crossing crate boundaries: the contracts every crate depends on.
                  - Entry points: where execution begins for the primary use case.
                  - External dependencies of note: any third-party services, databases, message brokers.
                  - This document is prose, not code. A new contributor must understand the system in 30 minutes from this document alone. Update it when the architecture changes.

                  **When to split into multiple crates:**
                  - Split when two components have genuinely independent concerns separated by a clean, stable interface.
                  - Split when a component is independently useful to downstream crates today, not hypothetically.
                  - Split when compilation requirements differ: `#![no_std]` crates, crates with C FFI boundaries, crates with conflicting feature flag semantics.
                  - Split when compile time becomes a problem and the component has a stable interface that rarely changes.
                  - Do not split to achieve "clean architecture" layering. That is a module concern, not a crate concern.
                  - Do not split preemptively. Start with one crate. Split when a concrete, present-day reason exists.
                  - Do not create crates named `util`, `helpers`, `common`, `shared`, `types`, or `core` (unless it is the `core` foundational crate). These names signal no clear owner. Every piece of code belongs to the crate that owns its concern.

                  **Domain-centric crate organization:**
                  - Organize by domain concept, not by technical layer.
                  - Correct: `crates/auth/`, `crates/billing/`, `crates/notification/`, `crates/storage/`.
                  - Forbidden: `crates/models/`, `crates/handlers/`, `crates/services/`, `crates/repositories/`.
                  - A domain crate owns its domain end-to-end: types, logic, persistence, and error handling.
                  - Cross-cutting concerns (tracing, metrics, configuration, database connection pool) live in their own crates. Domain logic never takes a dependency on another domain crate directly — only through explicitly defined trait interfaces.

                  **Crate naming:**
                  - Crate directory names and Cargo package names: `kebab-case`. Never underscores in crate names. Never `-rs` or `-rust` suffix (the crate is already Rust; stating it is redundant).
                  - Module names inside a crate: `snake_case`.
                  - Binary crate names: same as the main product name, `kebab-case`.

                  **Feature flags:**
                  - Feature names: plain nouns or compound nouns. `serde`, `async`, `std`, `tokio`, `tracing`. Never `use-serde`, `with-async`, `enable-std`, `feature-tracing`.
                  - The standard library feature: always named `std`.
                  - Negatively-framed feature names: forbidden. `no-alloc`, `disable-logging`, `without-std` — all forbidden.
                  - Additive features only: enabling a feature adds functionality, never removes it. Never use features as compile-time configuration switches.
                  - Do not use features as a substitute for `#[cfg(target_os = "...")]`. Use `cfg` for platform conditions.
                  - Every feature is documented with a `/// # Features` section in `lib.rs` explaining what it enables and what dependencies it pulls in.
                  - Features that enable large optional dependencies (async runtimes, cryptography, serde) are off by default. The minimal build is the default build.

                  ---

                  ### File and Module Organization

                  **Standard Cargo layout — never deviate:**
                  - `src/lib.rs` — library crate root; contains module declarations and top-level re-exports only.
                  - `src/main.rs` — binary entry point; thin shell only.
                  - `src/bin/name.rs` — additional named binaries; filename is `kebab-case`.
                  - `tests/` — integration tests; each `.rs` file is a separate test binary.
                  - `benches/` — Criterion benchmarks; each `.rs` file is a separate benchmark binary.
                  - `examples/` — runnable example programs demonstrating the public API.
                  - `build.rs` — build script; only when required by a crate dependency (bindgen, protobuf compilation). Never for application logic.

                  **Module file form — exactly one correct form:**
                  - `src/module_name/mod.rs` — REQUIRED. This is the only accepted form for all module files.
                  - `src/module_name.rs` — FORBIDDEN without any exception. The flat form is never used.
                  - This rule applies to every module at every nesting level: `src/auth/mod.rs`, `src/auth/session/mod.rs`, not `src/auth.rs` or `src/auth/session.rs`.
                  - The only files exempt from this rule are those with special semantic meaning to Cargo itself: `src/lib.rs`, `src/main.rs`, `build.rs`.
                  - No "but this module is only 20 lines" exception. No "it doesn't have submodules" exception. `module_name/mod.rs` from the first line of the first module, always.
                  - Rationale: `mod.rs` makes the module boundary a directory. When the module grows, submodules are added without renaming files. The flat form forces a rename when a module gains submodules, breaking history.

                  **What belongs in one file:**
                  - One source file defines one primary type plus everything exclusively serving that type: its `impl` blocks, its error type, its builder type, its iterator types, its private helper functions.
                  - A file defining `User` may contain `UserError`, `UserBuilder`, `UserIter`, and private functions used only by `User` — nothing unrelated.
                  - A file exceeding 400 lines must be split into submodules. No exceptions. If it cannot be split, the type is doing too much — split the type.
                  - Two types that can be modified independently belong in separate files.
                  - Helper functions shared by multiple types in the same module are in `src/module_name/internal.rs` (`mod.rs` declares `mod internal;`). They are `pub(super)` or private, never `pub`.

                  **Module naming and boundaries:**
                  - Module names: singular nouns. `user`, `order`, `config`, `session` — not `users`, `orders`, `configs`, `sessions`.
                  - A module boundary is a semantic boundary. Modules group things that change together and are used together. If two things in the same module never interact, they belong in different modules.
                  - Never create a module named `util`, `helper`, `common`, `misc`, `shared`, `types`, `models`, or `data`. These names signal that the code has no owner. Assign each piece to the module that owns its concern.
                  - Never create a module just to avoid naming: a `conversion` module for `From` impls means the `From` impls belong in the source type's module.
                  - Circular module dependencies are impossible in Rust. If you find yourself trying to create a circular reference between modules, the module boundaries are wrong — redesign them.

                  **Imports (`use`) — always this exact ordering, enforced by `rustfmt`:**
                  - Group 1: `std`, `core`, `alloc` imports.
                  - Group 2: external crate imports (one blank line separating from group 1).
                  - Group 3: crate-internal imports (`use crate::`, `use super::`, `use self::`) — one blank line from group 2.
                  - Within each group: alphabetical order.
                  - `use super::*` is forbidden everywhere except as the first statement inside `mod tests`, where it brings the module under test into scope.
                  - `use crate::*` is forbidden everywhere without exception.
                  - `use` statements appear at the top of the file, never inline inside function bodies or `impl` blocks.
                  - Wildcard imports (`use foo::*`) are forbidden everywhere except `mod tests` and generated code (e.g., `sqlx::query!` macros). Every import is explicit.
                  - Import the type, not the module, unless the module prefix adds semantic clarity: `use crate::auth::User` not `use crate::auth` then `auth::User` everywhere.

                  **Re-exports (`pub use`):**
                  - `pub use` is used only at the crate root (`lib.rs`) to flatten the public API surface.
                  - Never inside internal modules to shortcut import paths within the crate.
                  - Re-export the type, not the module: `pub use self::user::User`, not `pub use self::user`.
                  - Re-exported items form the stable public API contract. Adding a re-export is a commitment. Removing it is a breaking change.
                  - Items not re-exported from `lib.rs` are internal implementation details, even if individually `pub`.

                  ---

                  ### Naming (RFC 430 — complete and strict)

                  **Casing — every item has exactly one correct casing, no discretion:**
                  - Crates: `kebab-case`.
                  - Modules: `snake_case`.
                  - Types (structs, enums, unions, type aliases, trait definitions): `UpperCamelCase`.
                  - Enum variants: `UpperCamelCase`.
                  - Functions, methods, associated functions: `snake_case`.
                  - Macros: `snake_case!`.
                  - Constants (`const`): `SCREAMING_SNAKE_CASE`.
                  - Statics (`static`): `SCREAMING_SNAKE_CASE`.
                  - Local variables: `snake_case`.
                  - Generic type parameters: `UpperCamelCase` (descriptive names) or single uppercase letter only when implementing standard library traits that use those exact letters.
                  - Lifetime parameters: `'lowercase_snake_case` or single letter `'a`.

                  **Acronyms — zero exceptions, zero special cases (RFC 430):**
                  - In `UpperCamelCase`: every acronym is treated as one word, capitalized only at the start. `Uuid` not `UUID`. `XmlParser` not `XMLParser`. `HttpClient` not `HTTPClient`. `IoError` not `IOError`. `Api` not `API`. `Json` not `JSON`. `Url` not `URL`. `Html` not `HTML`. `Css` not `CSS`. `Tls` not `TLS`. `Rpc` not `RPC`. `Tcp` not `TCP`. `Udp` not `UDP`. `Sql` not `SQL`.
                  - In `snake_case`: acronyms are entirely lowercase. `parse_xml` not `parse_XML`. `http_client` not `HTTP_client`. `sql_query` not `SQL_query`.
                  - In `SCREAMING_SNAKE_CASE`: acronyms are entirely uppercase, separated by `_` if needed: `MAX_HTTP_RETRIES` not `MAX_HTTPRetries`.
                  - A single-letter abbreviation in `snake_case` is only acceptable as the final component of a compound name: `btree_map` (correct), `b_tree_map` (wrong).

                  **Variable names — full English words, no abbreviations:**
                  - Variable names are full English words that describe the semantic content of the value.
                  - These abbreviations are forbidden without any exception: `kb`, `mb`, `gb`, `tb`, `n`, `num`, `cnt`, `val`, `tmp`, `temp`, `res`, `result` (use a descriptive name), `ret`, `err` (use `error`), `e` (use `error`), `ok`, `resp`, `response` is fine, `req` (use `request`), `msg` (use `message`), `buf` (use `buffer`), `ptr`, `idx` (use `index`), `pos` (use `position`), `len` (use `length`), `sz` (use `size`), `cfg` (use `config`), `ctx` (use `context`), `arg` (use the argument name), `opts` (use `options`), `info`, `data`, `obj`, `item`, `node`, `curr` (use `current`), `prev` (use `previous`), `nxt` or `next` without a descriptive prefix, `src` (use `source`), `dst` (use `destination`), `out` (use `output`), `inp` (use `input`), `cmd` (use `command`), `srv` (use `server`), `svc` (use `service`), `evt` (use `event`), `pkt` (use `packet`), `hdr` (use `header`), `ref` (use a descriptive name), `conn` (use `connection`), `db` (use `database`), `tx` (use `transaction` or `sender`), `rx` (use `receiver`).
                  - The only accepted single-letter variable names are `i` and `j` as loop counters, and only when the loop body is a single line and the index has no semantic meaning beyond its numeric position.
                  - Descriptive loop counter names when semantics matter: `row_index`, `column_index`, `retry_count` — not `i`, `j`, `k`.

                  **Constant names:**
                  - All constants are named for what they represent, not for their value: `const MAX_RETRY_COUNT: u32 = 3` not `const THREE: u32 = 3`.
                  - Units are part of the name when the constant has a unit: `const TIMEOUT_MILLISECONDS: u64 = 5000`, `const MAX_PAYLOAD_BYTES: usize = 65536`.
                  - Avoid `const DEFAULT_*` names. Name the thing specifically: `const DEFAULT_POOL_SIZE: usize = 10` is acceptable; `const DEFAULT: u32 = 0` is forbidden.

                  **Boolean fields and variables:**
                  - Named as predicates (interrogative phrases that answer "yes or no").
                  - Correct: `is_valid`, `has_children`, `was_updated`, `can_retry`, `should_flush`, `needs_refresh`, `is_authenticated`, `has_permission`, `can_proceed`.
                  - Forbidden: bare adjectives `valid`, `active`, `done`, `ready`, `complete`, `enabled`, `dirty`, `open`, `closed`, `running`, `stopped`. These read as nouns or adjectives, not predicates.

                  **Method and function naming:**
                  - Functions returning `bool` MUST have a predicate prefix: `is_`, `has_`, `can_`, `should_`, `was_`, `needs_`. `fn valid(&self) -> bool` is forbidden; write `fn is_valid(&self) -> bool`. No exceptions.
                  - Functions performing an action (returning `()` or `Result<()>`) must be imperative verbs: `send`, `write`, `update`, `delete`, `flush`, `reset`, `initialize`, `close`, `connect`, `authenticate`, `validate`. Never nouns (`sender`, `writer`).
                  - Functions returning a computed value (not a simple field getter): verb phrases describing what is computed. `fn compute_checksum(&self) -> u32`, `fn find_nearest_neighbor(&self, point: Point) -> Option<Node>`.
                  - Getters: named after the field, no `get_` prefix: `fn id(&self) -> &UserId`, not `fn get_id(&self) -> &UserId`. This is the Rust convention. The `get_` prefix is a Java habit.
                  - Exception: `get` is acceptable only when it is part of an established domain term (`get_or_insert`, `get_or_default` pattern from standard library).
                  - Setters (when needed): `fn set_name(&mut self, name: Name)`. Must take ownership of the new value.
                  - Predicates on collections: `fn contains(&self, item: &T) -> bool`, `fn is_empty(&self) -> bool`.

                  **Conversion method naming — exact rules from the Rust API guidelines:**
                  - `as_foo(&self) -> &Foo`: zero-cost view; borrowed input to borrowed output. No allocation. Example: `str::as_bytes()`, `Path::as_os_str()`.
                  - `to_foo(&self) -> Foo`: potentially expensive; creates a new owned value by copying or converting. Example: `str::to_string()`, `[T]::to_vec()`, `Path::to_path_buf()`.
                  - `into_foo(self) -> Foo`: consumes `self`, transfers or transforms ownership. Example: `String::into_bytes()`, `OsString::into_string()`.
                  - Mutable accessor variants follow the return type word order, not the operation: `as_mut_slice()` not `as_slice_mut()`. `as_mut_ptr()` not `as_ptr_mut()`.
                  - `_unchecked` suffix: unsafe variant that skips bounds or validity checking. Always `unsafe fn`. Never skip the `_unchecked` suffix when the safe version exists.

                  **Constructor naming:**
                  - Primary infallible constructor: always `new()`. Never `create()`, `make()`, `build()`, `construct()`, `init()`, `from_default()`.
                  - Fallible primary constructor: `try_new()` returning `Result<Self, Error>`. Never `new()` returning `Option` or panicking on failure.
                  - Secondary named constructors: use established domain verbs. `open()` for files and connections. `connect()` for network clients. `bind()` for servers. `spawn()` for threads and tasks. `from_str()` / `parse()` for string parsing (implement `FromStr`). `from_file(path: &Path)` for file-based construction.
                  - `with_capacity(n)`, `with_timeout(duration)`, `with_options(options)` for constructors with a single key configuration parameter.
                  - Never `new_with_*()`. Use a builder when the construction has too many parameters.

                  **Generic type parameters:**
                  - Single-letter parameters (`T`, `U`, `E`, `K`, `V`, `F`, `I`) are ONLY acceptable when implementing a standard library trait that uses those exact letters: `impl<T> From<T>`, `impl<K, V> Index<K>`, `impl<I: Iterator> ...`, `impl<F: Fn()> ...`.
                  - All other generic type parameters use descriptive `UpperCamelCase`: `Item`, `Key`, `Value`, `Error`, `State`, `Codec`, `Reader`, `Writer`, `Strategy`, `Callback`, `Handler`, `Executor`, `Scheduler`, `Filter`, `Predicate`, `Transformer`, `Visitor`, `Builder`, `Encoder`, `Decoder`.
                  - When a type parameter is constrained to a specific trait, name it after what it does: `Serializer`, `Deserializer`, `Hasher`, `Formatter` — not `S`, `D`, `H`, `F`.
                  - Lifetime parameters: `'a`, `'b` for short anonymous lifetimes. Descriptive names for semantically meaningful lifetimes: `'input`, `'output`, `'arena`, `'session`, `'db`, `'scope`, `'env`.

                  **Iterator type names — must exactly match the method:**
                  - The type returned by `iter()` is named `Iter` or `FooIter`: `struct FooIter<'a>`.
                  - The type returned by `iter_mut()` is named `IterMut` or `FooIterMut`: `struct FooIterMut<'a>`.
                  - The type returned by `into_iter()` is named `IntoIter` or `FooIntoIter`: `struct FooIntoIter`.
                  - These names are not negotiable. They match standard library naming. Any other name is wrong.

                  **No variable shadowing:**
                  - Never shadow a variable name within a scope. Assign a new name that describes the transformation.
                  - Wrong: `let user = fetch_user(id)?; let user = user.validate()?; let user = user.into_active()?`.
                  - Right: `let raw_user = fetch_user(id)?; let validated_user = raw_user.validate()?; let active_user = validated_user.into_active()?`.
                  - Shadowing hides the history of a value and creates confusion when reading the code nonlinearly.
                  - Exception: the `use_` convention for `Result`/`Option` unwrapping is not shadowing but renaming — e.g., `let value = value?` where the error is propagated is acceptable only in one-liner transformation chains.

                  ---

                  ### Visibility

                  - All items default to private. This is correct. Do not fight it. Do not make things more visible "just in case."
                  - `pub`: items forming the crate's external API. This is a commitment that cannot be broken without a major version bump.
                  - `pub(crate)`: accessible throughout the crate, not from dependents. Use for cross-module internal APIs.
                  - `pub(super)`: accessible only to the parent module. Use for items needed by the parent but not the whole crate.
                  - `pub(in path)`: accessible only within the specified module path. Use sparingly and only when `pub(super)` is not precise enough.
                  - Private (no modifier): everything else. The default. Prefer it.
                  - Never make an item more visible than the narrowest scope that requires it.
                  - A `pub(crate)` item used in only one module should be private to that module.
                  - `pub` struct fields: forbidden without exception. Struct internals are always private. Expose data via getter methods.
                  - Exception: plain data structs with no invariants that are explicitly documented as `#[non_exhaustive]` C-compatible data types may have `pub` fields. These must be documented as such.
                  - `#[non_exhaustive]` on public enums and structs prevents downstream code from exhaustively matching variants or constructing the type. Use it on all public types that may gain variants or fields in future minor versions.

                  ---

                  ### Domain Modeling and Type-Driven Design

                  This is the most important section. Domain modeling separates programs that compile from programs that are correct.

                  **Make illegal states unrepresentable — the foundational principle:**
                  - If an invalid combination of values can be expressed by the type, the type is wrong. Redesign it.
                  - `Option<Option<T>>` is always wrong. Either flatten to `Option<T>` with distinct semantics or create a three-state enum with named variants.
                  - A struct with a `bool` flag that is only meaningful when another field is `Some` is wrong. Model with an enum: the flag and the associated data belong in the same variant.
                  - Two fields that must always be set together: nest them in a struct. `(name: Option<String>, display_name: Option<String>)` where both are always `Some` or always `None` → `profile: Option<DisplayProfile>`.
                  - Two fields where exactly one must be `Some` at a time: use an enum, not two `Option` fields.
                  - A `Vec<Option<T>>` usually signals that the `None` elements should be removed before the collection is stored. Filter eagerly.
                  - Any integer that is used as a status code or discriminant: use a typed enum, not an integer.

                  **Domain primitives — every domain value is a named type:**
                  - Raw primitives (`u64`, `i32`, `usize`, `String`, `Vec<T>`, `[u8; N]`, `bool`) are vocabulary for the machine, not the domain.
                  - Every domain value is wrapped in a named type immediately at the system boundary. Values are never passed through the domain as raw primitives.
                  - `user_id: u64` is not a domain model. `user_id: UserId` is.
                  - Different domain concepts that share a primitive representation are different types: `UserId`, `PostId`, `CommentId`, `SessionId` — all `u64` internally, but incompatible types. Passing a `PostId` where a `UserId` is expected is a compile error, not a runtime error.
                  - Units must be encoded in the type: `Milliseconds { value: u64 }`, `Bytes { value: usize }`, `Percentage { value: f64 }` — not bare `u64`, `usize`, `f64`.

                  **Type-state pattern — compile-time state machine enforcement:**
                  - Objects with lifecycle states use distinct types per state. The compiler enforces valid transitions.
                  - State transitions consume the old state type and return the new state type. If `authenticate()` consumes `Session<Unauthenticated>` and returns `Session<Authenticated>`, it is impossible to call `authenticate()` twice or to call authenticated methods before authenticating.
                  - Zero-sized marker types represent states with zero runtime cost:
                    `struct Unauthenticated;` `struct Authenticated;` `struct Connected;` `struct Disconnected;`
                  - `PhantomData<State>` carries the state type in the generic struct without affecting layout:
                    `struct Connection<State> { socket: TcpStream, state: PhantomData<State> }`
                  - Methods are implemented only on the state types where they are valid. Invalid operations do not exist on the type — they cannot be called. The error is at compile time.
                  - Type-state adds zero runtime overhead. The `PhantomData` is zero-sized. The state types are zero-sized. The monomorphized methods are identical to non-generic methods.
                  - Use type-state for: builder patterns (required fields enforced), connection/session lifecycle, protocol handshake sequences, resource acquisition and release.

                  **Enums as closed alternatives:**
                  - Enums model a value that is exactly one of a closed, known set of alternatives.
                  - When adding a new variant to a public enum would be a breaking change, annotate with `#[non_exhaustive]`.
                  - Every enum variant carries exactly the data that is valid in that state and no other data. No `Option` fields on enum variants that are always `None` in that variant.
                  - Enums over `bool` parameters: `fn process(mode: ProcessMode)` not `fn process(is_fast: bool)`. A boolean parameter is an enum in disguise.
                  - `Option<bool>` is forbidden in all cases. Three-state values need a three-variant enum with named variants.
                  - An enum with a single variant is a struct — use a struct.
                  - An enum that wraps another single type with no other variants is a newtype — use a newtype struct.

                  **State machines:**
                  - Any value that transitions through a sequence of states is an enum or a type-state generic.
                  - State transition functions are methods on the current state type (type-state) or take `self` and return `Self` (enum).
                  - Invalid transitions are rejected at compile time (type-state) or return `Err` with a descriptive error (enum approach).
                  - State data is stored in the variant or the generic, not in a separate `Option` field.

                  **Builder pattern for complex construction:**
                  - Types with more than four construction parameters use a builder.
                  - Required parameters are passed to `FooBuilder::new(required1, required2)`. Optional parameters are set via methods. This makes required vs. optional unambiguous.
                  - The builder enforces required fields at compile time using type-state: `FooBuilder<NoEmail>` and `FooBuilder<WithEmail>`, where `build()` is only available on `FooBuilder<WithEmail>`.
                  - `build()` returns `Result<Foo, FooBuilderError>` when construction can fail due to validation.
                  - The builder type is named `FooBuilder`. It lives in the same module as `Foo`, in the same file (`foo/mod.rs`).
                  - Non-consuming builder methods: `fn set_x(&mut self, value: X) -> &mut Self` — enable method chaining without consuming the builder.
                  - Consuming builder methods: `fn with_x(mut self, value: X) -> Self` — for builders that must be consumed.

                  **Session types for sequential protocols:**
                  - Network protocols, binary format parsers, and sequential state machines model each step as a distinct type.
                  - Each step returns a type representing exactly what can happen next. The caller cannot skip steps.
                  - Example: a parser that must read a header before reading a body returns `BodyParser` from `HeaderParser::parse_header()`. `BodyParser::parse_body()` is not callable without first parsing the header.

                  ---

                  ### Types and Data Modeling

                  **Structs:**
                  - Structs model data that belongs together and changes together.
                  - All fields are private. Invariants are enforced in `new()` or `try_new()` and maintained by methods.
                  - A struct whose fields could independently belong to different concepts is split into multiple structs.
                  - Unit structs (no fields): implement traits when no data is needed. `struct JsonEncoder;` implementing `Encoder`.
                  - Structs holding references require explicit lifetime annotations. Default to `String` (owned) over `&str` (borrowed) in structs; add lifetime parameters only when profiling proves allocation is a bottleneck.
                  - Every struct with invariants that are not expressible in the type system is documented with a `# Invariants` section in its doc comment.

                  **Tuple structs — COMPLETELY AND UNCONDITIONALLY FORBIDDEN:**
                  - The tuple syntax in struct definitions is forbidden in every case without any exception.
                  - `struct Foo(Bar)` — forbidden.
                  - `struct UserId(u64)` — forbidden.
                  - `struct Wrapper(Inner)` — forbidden.
                  - `struct Unit()` — forbidden (use `struct Unit;`).
                  - There is no argument, no "it's just one field," no "it's cleaner" rationale that makes a tuple struct acceptable. Named fields communicate intent. Positional access communicates nothing. A field named `value` tells the reader that this field holds the value. A field accessed as `.0` tells the reader nothing.
                  - Named-field form is ALWAYS correct:
                    - `struct UserId { value: u64 }` — correct.
                    - `struct EmailAddress { value: String }` — correct.
                    - `struct Wrapper { inner: Inner }` — correct.
                    - `struct Pair { first: A, second: B }` — correct.
                  - This rule has zero exceptions. Zero.

                  **Tuples — FORBIDDEN for any structured data crossing function boundaries:**
                  - Tuples are NEVER used to group related data. Define a named struct.
                  - Functions never return tuples of two or more values that are passed to a caller: `-> (String, u64)` is forbidden. Return a named struct: `-> ParseResult`.
                  - Functions never accept tuple parameters for structured input: `fn process(input: (String, u64))` is forbidden. Accept a struct.
                  - The only accepted context for tuples: destructuring of standard library iterators where the tuple is immediately consumed in the same expression and not passed to another function. `for (key, value) in map.iter() { ... }` is acceptable. `let pair = map.iter().next().unwrap()` then `pair.0` later is forbidden.
                  - `(T, U)` as a named type alias is forbidden. Define a named struct.

                  **Newtypes — always named-field form:**
                  - Every domain value that is a single primitive wrapped for type safety is a named-field struct.
                  - `struct UserId { value: u64 }` — the field is always named `value` for single-value newtypes.
                  - The field is private.
                  - Accessor method: exactly one method named `value()` exposing the inner value. `pub fn value(&self) -> u64` for `Copy` types. `pub fn value(&self) -> &T` for non-`Copy` types. No other accessor name (`inner`, `raw`, `get`, `unwrap`, `as_inner`) is ever used.
                  - Construction: only via `new()` or `try_new()`. `UserId { value: 42 }` outside `impl UserId` is forbidden.
                  - Minimum derives: `Debug`, `Clone`, `PartialEq`, `Eq`.
                  - Add `Copy` only when the inner type is `Copy` and copy semantics are correct for the domain concept.
                  - Add `Hash` when used as a map key (requires `Eq`).
                  - Add `PartialOrd`, `Ord` when the ordering has domain meaning.
                  - Add `Display` when the value is shown to users.
                  - Add `Serialize`, `Deserialize` when the type crosses a serialization boundary.
                  - Implement `From<InnerType>` for construction from the primitive.
                  - Implement `Display` to control how the value is shown — never rely on the inner type's `Display` by accident.

                  **Enums — structural rules:**
                  - Enum variants with two or more data fields use named-field (struct-like) syntax: `Move { x: i32, y: i32 }`, never positional `Move(i32, i32)`.
                  - Single-field tuple variants are acceptable only when the variant wraps exactly one existing type and the meaning is unambiguous: `Io(io::Error)`, `Parse(ParseError)`. This is the one location where tuple syntax is permissible.
                  - Zero-data variants: unit variants, no parentheses. `Running`, `Stopped`, `Pending` — not `Running()`.
                  - Enum variant names must not repeat the enum name: `Status::Active` not `Status::StatusActive`. `Color::Red` not `Color::ColorRed`.

                  **Type selection guide — one right answer per situation:**
                  - Single value with meaningful identity and type safety → newtype named-field struct.
                  - Multiple values that always travel together → named-field struct.
                  - A value that is exactly one of N known alternatives → enum.
                  - A value that is one of N alternatives with different associated data → enum with variant data.
                  - A set of independent boolean flags where any combination is valid → `bitflags` crate.
                  - A value that could be absent → `Option<T>`. Never a sentinel value (`-1`, `""`, `0`, null pointer, empty vec).
                  - A computation that could fail → `Result<T, E>`.
                  - A value shared across threads → `Arc<T>` with inner `Mutex<T>` or `RwLock<T>` if mutable.
                  - A value unique to one thread, shared within that thread → `Rc<T>` — but `Rc<T>` is forbidden in this codebase (use `Arc<T>` uniformly, the overhead is negligible).

                  **Derive order — always this exact sequence, only include what is needed:**
                  `#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, Serialize, Deserialize)]`

                  Every struct and enum derives `Debug`. No exceptions, ever. Code that does not derive `Debug` on a type is incomplete.

                  ---

                  ### Error Handling

                  **The panic family — strict prohibition:**
                  - `unwrap()` is forbidden in all non-test code. Zero exceptions.
                  - `expect(message)` is only for violated invariants that correct code cannot trigger at runtime. The message describes the invariant, not the operation: `expect("sender is always initialized before first use")` not `expect("should not be None")` or `expect("unreachable")`.
                  - `panic!` is forbidden in library code entirely. Accepted in binary `main.rs` only as an absolute last resort for unrecoverable startup failures that cannot be expressed as `Result`.
                  - `todo!()` is forbidden in committed code. If something is not implemented, it does not compile. A `todo!()` is a build failure waiting to happen in production.
                  - `unimplemented!()` is forbidden in committed code for the same reason.
                  - `unreachable!()` is accepted only inside a `match` arm that is statically unreachable given the type system invariants, preceded by a comment: `// UNREACHABLE: <precise reason the type system guarantees this arm is never entered>`. The comment must be specific enough that a reader can verify the invariant independently.
                  - `assert!` in non-test code is allowed only to verify preconditions at system entry points (public API boundary validation). Inside library logic, use `Result` instead.

                  **Result types — strict rules:**
                  - Every public function that can fail returns `Result<T, E>` where `E` is a concrete named error type defined in this crate.
                  - `Result<T, ()>`: forbidden. A unit error type communicates nothing. Define a zero-field error struct with a description.
                  - `Result<T, String>`: forbidden. String errors cannot be matched by callers. Define a typed enum.
                  - `Result<T, Box<dyn Error>>`: forbidden in library code. The error is erased. Define a typed enum.
                  - `Result<T, Box<dyn Error + Send + Sync>>`: forbidden in library code for the same reason.
                  - `Option` vs `Result`: use `Option` only when the absence of a value is a normal, non-exceptional outcome (e.g., looking up a key that might not exist). Use `Result` when absence represents a failure (e.g., parsing a required field).

                  **Library vs. application error handling — never mix:**
                  - Library crates (`crates/auth/`, `crates/billing/`, all crates under `crates/` except the binary): use `thiserror::Error` exclusively. Errors are typed enums. Callers can match on specific variants. Never `anyhow` in a library — it erases type information.
                  - Application binary crate (`main.rs`, integration layer): use `anyhow::Error` with `.context(...)`. Error chains explain causality: "authenticating user" wrapping "reading session from database" wrapping `io::Error`. Never use bare `thiserror` errors in application code without wrapping context.

                  **Error type definition (library crates):**
                  - Error types are enums annotated with `#[derive(Debug, thiserror::Error)]`.
                  - Every variant has `#[error("descriptive message")]` written from the user's perspective: what went wrong, not what function was called. `#[error("email address is invalid: {address}")]` not `#[error("validate_email failed")]`.
                  - Variants wrapping a source error use `#[source]` or `#[from]`. Use `#[from]` when the source error type maps unambiguously to exactly one variant. Use `#[source]` with a manual `From` impl when one source type maps to multiple variants depending on context.
                  - Error types implement `Send + Sync`. This is provided automatically by `thiserror` when all variant fields are `Send + Sync`.
                  - Error enum names end in `Error`: `ParseError`, `ConnectionError`, `ValidationError`, `AuthError`.
                  - Error type lives in the same module as the type it describes: `src/auth/mod.rs` contains `AuthError`. Never a global `errors.rs` module.
                  - Error variants are named for the condition, not the operation: `InvalidEmail` not `EmailValidationFailed`. `ConnectionTimeout` not `FailedToConnect`.
                  - No `Other(String)` catch-all variant. Every error condition is a named variant. If a specific variant cannot be defined, the error handling design is wrong.

                  **Application error handling (`main.rs` and integration code):**
                  - Function signatures: `fn main() -> anyhow::Result<()>` or `async fn main() -> anyhow::Result<()>`.
                  - Every `?` propagation: `.context("lowercase past-tense description of what was happening")` or `.with_context(|| format!("description with {}", dynamic_value))`.
                  - Context strings: lowercase, past tense, no trailing period, no capital letters mid-string: `"reading config file"`, `"connecting to database"`, `"parsing user input"`. Not `"Read Config File"`, not `"Failed to read config file."`.
                  - Error display at the program top level: use the `{:#}` alternate format for `anyhow::Error` to display the full error chain.

                  **Propagation mechanics:**
                  - Use `?` for all error propagation. Never `match result { Ok(v) => v, Err(e) => return Err(e) }`.
                  - When `?` requires a type conversion, implement `From<SourceError> for TargetError` — do not use `.map_err(|e| TargetError::from(e))` when `From` would be automatic.
                  - `.ok()` to silently discard an `Err` is forbidden. Either propagate, log and discard with a comment, or explicitly match.
                  - `.map_err(|_| ...)` discards error information and requires a comment: `// discarding source error because <reason>`.
                  - `.unwrap_or_default()` requires a comment: `// default is semantically correct here because <reason>`.

                  ---

                  ### Traits

                  **When to define a trait:**
                  - Define a trait only when at least two concrete types will implement it AND callers need to be polymorphic over them right now, not hypothetically.
                  - Never define a trait for a single implementation. It adds indirection, makes the code harder to understand, and provides no benefit.
                  - Never define a trait for "future extensibility." Future extensibility that does not exist today is complexity that exists today.
                  - The rule of three: do not extract a trait until the third concrete type genuinely needs it. Two cases may be coincidental similarity, not a real abstraction.
                  - After defining a trait, immediately ask: could I have written this without the trait? If yes, delete the trait.

                  **Standard library traits — implement all that apply to the type:**
                  - `Debug` — every public type. Zero exceptions.
                  - `Display` — any type shown to users or logged. Never use `Debug` output for user-facing text.
                  - `Clone` — any type that can logically be duplicated. Derive when the automatic implementation is correct.
                  - `Copy` — any type that is small, cheap to copy, and has value semantics. Requires all fields to be `Copy`. Add the comment `// Copy: no heap resources, value semantics.`
                  - `PartialEq` and `Eq` — any type with a meaningful notion of equality. Both are almost always derived together.
                  - `PartialOrd` and `Ord` — any type with a meaningful total ordering. Requires `PartialEq + Eq`. Derived together.
                  - `Hash` — any type used as a `HashMap` or `HashSet` key. Requires `Eq`. If `PartialEq` is manually implemented, `Hash` must also be manually implemented with the invariant: `a == b` implies `hash(a) == hash(b)`.
                  - `Default` — any type with a meaningful "zero" or "empty" state that can be constructed without parameters.
                  - `From<T>` — for every lossless, infallible conversion from type `T` to `Self`. Never implement `Into<T>` directly; the blanket impl derives it from `From`.
                  - `TryFrom<T>` — for every fallible conversion from type `T` to `Self`. Never implement `TryInto<T>` directly.
                  - `Iterator` — for any type that produces a sequence of values.
                  - `FromIterator<T>` — for any collection type that can be built from an iterator of `T` (enables `.collect::<Collection>()`).
                  - `Extend<T>` — for any collection type that can be extended from an iterator of `T`.
                  - `AsRef<T>` / `AsMut<T>` — when a type can cheaply provide a reference to an inner `T` without allocation.
                  - `Borrow<T>` — when a type can be borrowed as `T` for lookup operations (required for using owned types as HashMap keys that can be queried by `&str`).
                  - `Deref<Target = T>` / `DerefMut` — only for smart pointer types that transparently provide access to the inner `T`. Never for convenience.
                  - `Send` + `Sync` — derived automatically when all fields are `Send`/`Sync`. Manually implemented only when the struct contains raw pointers or `UnsafeCell`, with a `// SAFETY:` comment.
                  - `serde::Serialize` + `serde::Deserialize` — for all types that cross a serialization boundary.

                  **Never implement these directly (blanket impls provide them):**
                  - Never implement `Into<T>`. Implement `From<Other> for T`; the blanket impl provides `Into<T> for Other` automatically.
                  - Never implement `TryInto<T>`. Implement `TryFrom<Other> for T`.
                  - Never implement `ToString`. Implement `Display`; `ToString` is blanket-implemented for all `Display` types.
                  - Never implement `PartialOrd` without also implementing `Ord` when total ordering is valid.

                  **Trait objects vs. generics — choose based on dispatch needs:**
                  - `impl Trait` in argument position: the concrete type is known at compile time. Use for single-trait bounds. `fn process(input: impl Read)`.
                  - `<T: Trait>` named generic: when `T` appears more than once in the signature, or in the function body, or in the return type. `fn copy<Reader: Read, Writer: Write>(reader: &mut Reader, writer: &mut Writer)`.
                  - `dyn Trait`: the concrete type is unknown at compile time, or a heterogeneous collection of different concrete types is needed. `Vec<Box<dyn Handler>>`.
                  - Never `Box<dyn Trait>` as a convenience to avoid naming a type. The cost is a heap allocation plus a vtable indirection on every method call. For homogeneous collections, use `Vec<ConcreteType>`. For performance-critical dispatch, use generics.
                  - Design traits with object safety in mind when `dyn` usage is anticipated: no methods with `Self` in return position (unless behind `Box<Self>`), no generic methods.

                  **Generic struct bounds — do not duplicate derived bounds:**
                  - When `#[derive(Clone)]` is added to `struct Foo<T>`, do NOT add `T: Clone` to the struct definition.
                  - Wrong: `struct Foo<T: Clone> { value: T }`.
                  - Right: `struct Foo<T> { value: T }` with `#[derive(Clone)]`.
                  - The derived `Clone` implementation already handles the bound on `T`. Adding it to the struct definition creates a backwards-incompatibility hazard (external code that constructs `Foo<NotClone>` would break).
                  - Add bounds to `impl` blocks, not to struct definitions, unless the struct cannot be constructed without the bound.

                  **Sealed traits — prevent external implementation:**
                  - A public trait not intended for implementation by downstream crates uses the sealed trait pattern.
                  - Define a private module `mod sealed` containing a private trait `pub(crate) trait Sealed {}`.
                  - Make the public trait require `Sealed` as a supertrait: `pub trait MyTrait: sealed::Sealed {}`.
                  - Only types within the crate can implement `Sealed` and therefore `MyTrait`.
                  - Document the trait: `/// This trait is sealed and cannot be implemented outside of this crate.`

                  **Operator overloading — semantics must match mathematics:**
                  - Implement `Add` only when `a + b` means the same thing as mathematical addition.
                  - Implement `Mul` only when `a * b` has the associativity and distributivity properties of multiplication.
                  - Never implement operators to mean "append" or "combine" when those are not the mathematical operations.
                  - `Deref` and `DerefMut`: only for smart pointer types (`Box<T>`, `Arc<T>`, `String` → `str`, `Vec<T>` → `[T]`). Never implement `Deref` for a regular struct to get transparent field access.
                  - `Index` and `IndexMut`: only when integer or slice indexing has a clear, unambiguous semantics.

                  ---

                  ### Generics and Lifetimes

                  **Generics:**
                  - Use generics to eliminate code duplication when the type of the data changes but the algorithm does not.
                  - Minimize bounds: only constrain a generic to the traits the function body actually calls or the struct actually uses. Extra bounds restrict future callers unnecessarily.
                  - `impl Trait` in argument position for single-trait bounds on non-stored inputs. `fn process(input: impl Read)` is cleaner than `fn process<Reader: Read>(input: Reader)`.
                  - Named generics `<T: Trait>` when: the type name appears multiple times in the signature, the type is stored, or the function has three or more bounds.
                  - `where` clauses when: three or more bounds on a type, bounds on associated types (`T::Error: Display`), higher-ranked trait bounds (`for<'a> F: Fn(&'a T)`), or the inline bound would exceed 80 characters.
                  - Generic parameter ordering: lifetimes first, then type parameters, then const parameters. `struct Foo<'a, T, const N: usize>`.
                  - Const generics: for type-level array sizes, fixed-size buffers, and other constant values known at compile time. `struct Buffer<const CAPACITY: usize> { data: [u8; CAPACITY] }`.
                  - RPIT (return position `impl Trait`): return `impl Iterator<Item = T>` instead of collecting into `Vec<T>` when the caller may not need all elements. Do not box the iterator unless the return type varies at runtime.

                  **Lifetimes:**
                  - Add explicit lifetime annotations only when the compiler requires them and the three elision rules do not apply.
                  - Elision rule 1: each input `&T` or `&mut T` parameter gets its own distinct lifetime automatically.
                  - Elision rule 2: if exactly one input lifetime exists, it is used for all output lifetimes.
                  - Elision rule 3: in methods, the `&self` or `&mut self` lifetime is used for all output lifetimes.
                  - When the compiler requires explicit lifetimes, name them descriptively when their semantic meaning is significant: `'input` for a lifetime tied to the input string, `'arena` for a lifetime tied to an arena allocator, `'session` for a session-scoped lifetime.
                  - `'static` is used only when the value genuinely lives for the entire program duration: string literals, leaked allocations, globally-initialized data. Never add `'static` bounds to work around lifetime errors — find the correct lifetime relationship.
                  - Structs holding references require lifetime parameters. The struct cannot outlive the reference it holds. This is enforced by the compiler.
                  - `'a: 'b` lifetime bounds (outlives): `'a` outlives `'b`. Add only when the relationship is genuinely needed, not speculatively.

                  ---

                  ### Ownership and Borrowing

                  **The three rules of parameter passing:**
                  - Take `&T` when the function only reads the value.
                  - Take `&mut T` when the function mutates the value in place and the caller keeps ownership.
                  - Take `T` (ownership) when the function consumes or stores the value.
                  - These are not suggestions. Every parameter should be one of these three, and the choice communicates intent.

                  **Clone discipline:**
                  - Never clone to satisfy a borrow checker error. The borrow checker is correct. Restructure the code so the clone is not needed.
                  - Every `.clone()` call site has a comment explaining why cloning is the correct semantic choice here: `// clone: the config is shared across multiple requests and must outlive the current scope`.
                  - `.clone()` on a `Copy` type is forbidden. `Copy` types are implicitly copied; `.clone()` is misleading noise.
                  - `.to_owned()` converts `&str` to `String`. `.to_string()` also works but invokes `Display`. Use `.to_owned()` for type conversions, `.to_string()` for display formatting.

                  **Smart pointers — strict policies:**
                  - `Rc<T>`: forbidden in all cases. `Rc<T>` is single-threaded reference counting. Use `Arc<T>` uniformly. The cost difference is negligible and `Rc<T>` creates a class of bugs (`!Send` types that cannot be moved to threads).
                  - `Arc<T>`: use only when multiple owners across different scopes or threads genuinely need to share a value. Each `Arc<T>` usage has a comment explaining the ownership model.
                  - `Arc<Mutex<T>>` for shared mutable state across threads. Document the locking protocol.
                  - `Arc<RwLock<T>>` for shared state that is read frequently and written rarely. Document the invariants.
                  - `Box<T>`: for heap-allocated values where a single owner exists. For trait object dispatch: `Box<dyn Trait>`. For recursive types. For large stack data that must be heap-allocated.
                  - `Cell<T>` and `RefCell<T>`: interior mutability of last resort. Each use has a comment explaining why the borrow checker cannot verify safety statically and why the runtime check will never fail.

                  **Interior mutability:**
                  - `RefCell<T>`: runtime borrow checking. Only when `&mut self` cannot be threaded through but mutation is needed. Comment mandatory: `// RefCell: <reason static borrow checking is insufficient here>`.
                  - `Cell<T>`: for `Copy` types only. No comment needed if the pattern is idiomatic (`Cell<bool>` for a dirty flag).
                  - `Mutex<T>` and `RwLock<T>`: when mutation crosses threads. Always use `std::sync::Mutex` in synchronous code. Always use `tokio::sync::Mutex` in async code.
                  - Lock guards are dropped in the narrowest possible scope. Never hold a lock guard across an `.await` point. Use a `{ }` block to explicitly scope the guard.

                  **Thread safety:**
                  - Every type crossing thread boundaries implements `Send + Sync` correctly.
                  - `unsafe impl Send` or `unsafe impl Sync` requires a `// SAFETY:` comment explaining the precise invariant that makes this safe.
                  - `Arc<T>` is `Send + Sync` when `T: Send + Sync`. Document this assumption.
                  - `std::sync::Mutex` and `std::sync::RwLock` are `Send` but holding a guard is not. Never store a guard in a struct.

                  ---

                  ### Concurrency

                  **Shared state model:**
                  - Shared mutable state is always behind `Arc<Mutex<T>>` or `Arc<RwLock<T>>`. Never bare `*mut T` across threads.
                  - `Mutex<T>` for state that is both read and written frequently.
                  - `RwLock<T>` for state that is read much more often than written. Multiple readers are allowed simultaneously.
                  - Lock the minimum amount of data. If a struct has two independently mutable fields, use two separate `Mutex`es, not one `Mutex` over the whole struct.
                  - Never hold two locks simultaneously unless a strict, documented lock ordering prevents deadlocks. Document the ordering in a comment: `// Lock ordering: config_mutex always before cache_mutex`.

                  **Message passing model (preferred over shared state):**
                  - Prefer message passing (channels) over shared state when producers and consumers are on different threads with an asynchronous relationship.
                  - `std::sync::mpsc` for single-producer single-consumer synchronous channels.
                  - `tokio::sync::mpsc` for async multi-producer single-consumer.
                  - `tokio::sync::broadcast` when multiple consumers need the same message.
                  - `tokio::sync::watch` for single-producer multiple-consumer state updates (last value wins).
                  - Channels are typed. The message type is a named enum or struct, never `Box<dyn Any>`.
                  - Sender and receiver are named descriptively: `command_sender`, `event_receiver`, not `tx`, `rx`.

                  **Atomics:**
                  - `AtomicBool`, `AtomicUsize`, `AtomicU64` for simple counters, flags, and indices that need lock-free access.
                  - Use the weakest memory ordering that is correct. `Relaxed` for statistics counters. `Acquire`/`Release` for synchronization between producer and consumer. `SeqCst` only when global ordering is required — document why.
                  - Never use atomics as a substitute for a `Mutex` around complex multi-field state. Atomics work for single values only.

                  **Thread pool and task management:**
                  - `tokio::spawn` for async tasks. Each spawned task is either joined via its `JoinHandle` or added to a `JoinSet`. Fire-and-forget spawning is forbidden unless the task's lifecycle is explicitly documented as unobserved.
                  - `std::thread::spawn` for CPU-bound work outside the async runtime. Always join the thread handle before program exit.
                  - `tokio::task::spawn_blocking` for blocking operations called from async code. Add a comment: `// spawn_blocking: <reason this operation cannot be made async>`.
                  - Thread count is never hardcoded. Use `std::thread::available_parallelism()` for CPU-bound work. Use runtime configuration for IO-bound work.

                  **Deadlock avoidance:**
                  - Never acquire a lock while holding another lock unless the ordering is documented and enforced.
                  - Never hold a lock across an `.await` point in async code.
                  - Never hold a lock while calling unknown external code (callbacks, trait methods on user-provided types).
                  - Use `try_lock()` when failing to acquire a lock is an acceptable outcome. Use `lock()` only when the lock will eventually become available.

                  ---

                  ### Type Conversions — No Casts

                  - `as` casts are forbidden at all call sites without exception. If an `as` cast appears necessary, the type design is wrong.
                  - Numeric type suffix indicators on literals (`0u8`, `1usize`, `3i32`, `5.0f64`) are forbidden. If the compiler cannot infer the type from context, the API is wrong — fix the function signature or use a named constant.
                  - Lossless, infallible conversions: `From<T>` / `Into<T>`.
                  - Potentially lossy or fallible conversions: `TryFrom<T>` / `TryInto<T>`; handle the `Result` explicitly.
                  - String to type: implement `FromStr`. Use the blanket `.parse::<Type>()` method.
                  - Type to string: implement `Display`. Use `.to_string()` for display output, `.to_owned()` for type conversion.
                  - The one accepted location for `as u8`: inside a `From<EnumType> for u8` impl for a `#[repr(u8)]` enum, isolated in one place, with a `// SAFETY:` comment if needed. This is the only accepted numeric cast in the codebase.
                  - `.copied()` converts `Option<&T>` to `Option<T>` for `Copy` types. `Some(&value)` pattern matches on `Copy` type fields are forbidden — use `.copied()`.
                  - `.cloned()` converts `Option<&T>` to `Option<T>` for `Clone` types when cloning is the correct semantic choice. Add a comment explaining why cloning is needed.

                  ---

                  ### Iterators and Collections

                  **Iterator usage:**
                  - Iterator chains are preferred over imperative `for` loops.
                  - A `for` loop is used only when: (a) the body has stateful side effects that break iterator chain composition, or (b) the body is more than three lines and the chain would be less readable.
                  - Never manually index with `collection[i]` when `enumerate`, `zip`, `windows`, `chunks`, `chunks_exact`, `step_by`, or `split_at` provides the structural pattern.
                  - `.filter().map()` is forbidden when `.filter_map()` achieves the same result more concisely.
                  - `.flat_map(|x| x.into_iter())` is forbidden when `.flatten()` achieves the same result.
                  - `.iter().cloned()` on `Copy` types is forbidden. Use `.iter().copied()`.
                  - Never call `.clone()` inside an iterator chain. Clone before the chain or after collecting.
                  - Never `collect()` into a `Vec` only to immediately iterate over it again. Chain the adapters.
                  - `iter().for_each(|x| { /* multi-line body */ })` is forbidden. Use a `for` loop for multi-line bodies.
                  - `.collect::<Vec<_>>()` — the turbofish type annotation is always present when the target type cannot be inferred from context.
                  - Iterator chains that exceed a single statement in length are stored in a named variable: `let active_users = users.iter().filter(|u| u.is_active()).collect::<Vec<_>>();`. Do not chain 5 adapters inline as a function argument.
                  - `.peekable()` when look-ahead is needed. Never advance the iterator to "peek" and then repeat the logic.
                  - `.take(n)` to limit iteration count. `.take_while(predicate)` to stop at a condition.
                  - `.scan(state, |state, item| ...)` for stateful transformations that thread state through the iteration.
                  - `.zip(other_iter)` for parallel iteration over two collections. Never index both with the same `i`.
                  - `.unzip()` when a single iteration produces two separate collections.
                  - `.partition(predicate)` to split into two `Vec`s. Never iterate twice with different filters.
                  - `.fold(init, |acc, item| ...)` for reduction to a single value. The accumulator type is always named, never an anonymous intermediate.
                  - `.any(predicate)` and `.all(predicate)` for short-circuit boolean evaluation. Never `.filter(p).count() > 0`.

                  **Vec:**
                  - `Vec::new()` — empty Vec with no allocation until first push.
                  - `vec![a, b, c]` — Vec with known elements.
                  - `Vec::with_capacity(n)` — when the final element count is known or estimated before filling. Prevents repeated reallocations.
                  - `Vec::from([...])` — forbidden. Use `vec![...]`.
                  - `&Vec<T>` as a function parameter — forbidden. Use `&[T]` (a slice). Accepts `Vec<T>`, arrays, and other slices.
                  - `String` as a function parameter — forbidden when only reading. Use `&str`. Accepts `String`, `&str`, and `Cow<str>`.
                  - `.len() == 0` — forbidden. Use `.is_empty()`.
                  - `.len() != 0` — forbidden. Use `!collection.is_empty()`.
                  - `vec.clone()` to copy a Vec — add a comment explaining why the copy is needed.
                  - Sorting: `sort()` for total ordering. `sort_by_key(|x| x.field)` for field-based sorting. `sort_unstable()` when stability is not required (faster). Never implement a custom comparison when `sort_by_key` suffices.

                  **HashMap and HashSet:**
                  - `HashMap::new()` — forbidden. The hasher is `RandomState` and the map starts with no capacity. Use `HashMap::with_capacity(n)` when the approximate size is known, or `HashMap::default()`.
                  - `HashSet::new()` — forbidden for the same reason. Use `HashSet::with_capacity(n)` or `HashSet::default()`.
                  - `BTreeMap<K, V>` — when iteration order must be sorted, when deterministic iteration is required for reproducibility, or when range queries (`range()`) are needed.
                  - `BTreeSet<T>` — when set iteration must be sorted.
                  - Never iterate over a `HashMap` when the result order is observable to callers or affects correctness. Use `BTreeMap` or collect-then-sort.
                  - `.contains_key()` before `.insert()` is almost always wrong. Use `.entry().or_insert()` or `.entry().or_insert_with()`.
                  - `.get_or_insert()` — use the entry API, not get-check-insert.
                  - `.contains(&item)` on a `Vec` in non-trivial code paths is a code smell. If membership testing is needed, the collection should be a `HashSet` or `BTreeSet`.
                  - `IndexMap` from the `indexmap` crate when insertion order must be preserved during iteration and `HashMap` performance is needed for lookup.

                  **String building:**
                  - Build strings from multiple parts with `format!()` or `.collect::<String>()` on an iterator of `&str`.
                  - Repeated `.push_str()` in a loop is acceptable only when `String::with_capacity(n)` is used upfront and the final length is bounded.
                  - Multiple `format!()` calls whose results are concatenated: use a single `format!()` with the full template.
                  - `write!(&mut string, "...")` from `std::fmt::Write` for building large strings in tight loops where `format!` allocation overhead is measured and proven.

                  ---

                  ### Option and Result Combinators

                  - No combinator chain exceeds three steps. Beyond three, extract a named function with a descriptive name.
                  - `.map(|x| x.method())` with no additional arguments: use the method reference form `.map(Type::method)`.
                  - `.map(|x| other_function(x))`: use `.map(other_function)` when types align.
                  - `if let Some(x) = option { use(x); } else { return Err(e); }`: replace with `option.ok_or_else(|| e)?`.
                  - `if let Ok(x) = result { use(x); } else { return None; }`: replace with `result.ok()?` (in `Option`-returning context).
                  - `match option { Some(x) => f(x), None => default }`: replace with `option.map_or(default, f)` or `option.map(f).unwrap_or(default)`.
                  - Nested `Option<Option<T>>`: always wrong. Flatten or redesign the type.
                  - `.flatten()` for `Option<Option<T>>` → `Option<T>` (when the nesting is genuinely needed but the outer `Some` with inner `None` and outer `None` have the same meaning).
                  - `.flatten()` for `Result<Result<T, E>, E>` → `Result<T, E>` (when error types match).
                  - `.transpose()` for `Option<Result<T, E>>` ↔ `Result<Option<T>, E>` conversion.
                  - `.and_then(f)` for chaining fallible operations: `f` takes the value and returns `Option<U>` or `Result<U, E>`.
                  - `.or_else(f)` for providing a fallback that might fail: `f` takes the error and returns `Result<T, E>`.
                  - `let else` syntax for refutable patterns where the else branch diverges:
                    `let Some(value) = optional_value else { return; };`
                    `let Ok(parsed) = result else { return Err(error); };`
                    Use `let else` in preference to `if let` when the "else" case exits the current scope.

                  ---

                  ### Pattern Matching

                  - Every `match` is exhaustive. A `_ =>` wildcard arm is only acceptable when all uncovered variants are genuinely irrelevant AND a comment explains why: `// _ => remaining variants are internal states unreachable in this context`.
                  - `if let` is used for single-variant matching where the other case is handled by continuing execution. Two or more meaningful branches: use `match`.
                  - `match` arms contain at most three lines of logic. Longer: extract a named function and call it from the arm.
                  - `matches!(expression, Pattern)` replaces `match expression { Pattern => true, _ => false }`.
                  - `matches!(expression, Pattern if guard)` for pattern + guard.
                  - Nested `if let` inside another `if let` arm: replace with a single `match` on a tuple of both values when both conditions are semantically related.
                  - Pattern matching on tuples for struct-like data is forbidden. Destructure named structs. `let (a, b) = value` where `value` is a struct → `let MyStruct { field_a: a, field_b: b } = value`.
                  - Match guards (`if condition` in arm) are used only when the condition cannot be expressed as a pattern or a nested `match`.
                  - `@` bindings for capturing a matched value while also testing a pattern: `n @ 1..=100 => use(n)`.
                  - Binding by reference in patterns: `ref` and `ref mut` are used only when moving the matched value is impossible or incorrect. Prefer moving.
                  - `..` to ignore remaining struct fields in a pattern. Never list fields that are not used in the arm body (they clutter and do not communicate intent).
                  - Irrefutable patterns in `let` bindings: use only when the pattern is genuinely irrefutable.

                  ---

                  ### Strings

                  - Function parameters that take string input: `&str`. Never `&String`. `&str` accepts `String`, `&str`, `Cow<str>`, and string literals.
                  - Function return values producing owned strings: `String`.
                  - Function parameters that may or may not own a string: `Cow<'_, str>` — used when the function sometimes returns a borrowed string and sometimes an owned string to avoid unnecessary allocations.
                  - `format!("{}", x)` where the entire content is one value: replace with `x.to_string()`.
                  - `String::new()` for an empty string. `String::from("")`, `"".to_string()`, `"".to_owned()`, `"".into()` — all forbidden as "empty string" expressions.
                  - String concatenation: `format!()`. The `+` operator on `String` is forbidden: it moves the left operand and is unintuitive.
                  - `to_owned()` for converting `&str` to `String` as a type operation. `to_string()` for invoking `Display`. These are not interchangeable.
                  - File system paths: `PathBuf` (owned) or `&Path` (borrowed). Never `String` or `&str` for paths. `Path::new("foo")` for literals.
                  - Never store a `&str` in a long-lived struct without a lifetime parameter. Use `String` unless lifetime-parameterized borrowing is a deliberate optimization.
                  - String parsing: implement `FromStr` for types that can be parsed from strings. Use `.parse::<Type>()` at call sites.
                  - `str::contains`, `str::starts_with`, `str::ends_with` for simple checks. `regex` crate for complex patterns. Never implement ad-hoc character scanning when these methods apply.
                  - `str::split()` returns an iterator. Never collect into `Vec<&str>` unless multiple passes are needed.
                  - `.trim()`, `.trim_start()`, `.trim_end()` for whitespace removal at boundaries only. Never manual character iteration for trimming.

                  ---

                  ### Arithmetic and Numbers

                  - Integer overflow is always handled explicitly. Pick the correct operation:
                    - `checked_add`, `checked_sub`, `checked_mul`, `checked_div` — returns `None` on overflow; propagate as `Option`.
                    - `saturating_add`, `saturating_sub`, `saturating_mul` — clamps to `MIN`/`MAX`; use for values that should never exceed bounds.
                    - `wrapping_add`, `wrapping_sub`, `wrapping_mul` — intentional modular arithmetic; use for hash functions, checksums, explicit ring arithmetic.
                    - `overflowing_add` — returns `(result, bool)` when you need both the wrapped result and the overflow flag.
                    - Relying on debug-mode panic and release-mode wrap is forbidden. The behavior must be deterministic in both modes.
                  - Division: the `/` operator on integers panics on division by zero. Every division by a potentially-zero denominator uses `checked_div`. The divisor must be proven nonzero by a comment or a preceding `assert!` at a validated boundary.
                  - Lossy numeric conversions (e.g., `u64` to `u32`): `TryFrom`/`TryInto`; handle the `Result` with a descriptive error.
                  - Lossless numeric conversions (e.g., `u8` to `u64`): `From`/`Into`.
                  - `as` numeric casts: forbidden. No exceptions.
                  - Floating-point `==` and `!=`: forbidden. Use epsilon comparison or a dedicated float comparison library. `(a - b).abs() < EPSILON` with a named epsilon constant.
                  - Floating-point arithmetic in financial calculations: forbidden. Use the `rust_decimal` or `bigdecimal` crate.
                  - Integer literals for sizes and counts: named `const` values with units in the name. `const MAX_CONNECTIONS: u32 = 100` not the bare literal `100`.
                  - `usize` for sizes, indices, and lengths. `u64` for IDs and counters. `i64` for timestamps. `f64` for measurements where floating-point is genuinely appropriate. Never use a smaller integer type unless the struct layout or protocol specification requires it.

                  ---

                  ### Functions and Methods

                  **Function design:**
                  - Single responsibility. A function that does two things is two functions.
                  - Function body over 40 lines: split. No exceptions. If the logic genuinely requires 40+ lines to express, extract named helpers.
                  - Maximum cyclomatic complexity: 5. More than 5 branches in one function signals a missing abstraction.
                  - No "and" in function names: `validate_and_normalize` does two things. `validate` and `normalize` are two functions.
                  - Pure functions where possible: output depends only on input, no side effects. Side-effecting functions are documented with the effects they have.

                  **Parameter rules:**
                  - Minimum access: `&T` over `&mut T` over `T`. Pass the minimum access level needed.
                  - Read-only `Vec<T>` parameter: `&[T]`. Accept `Vec<T>`, arrays, and slices.
                  - Read-only `String` parameter: `&str`. Accept `String`, `&str`, and string literals.
                  - Read-only `PathBuf` parameter: `&Path`. Accept `PathBuf` and `&Path`.
                  - More than four parameters: define a configuration struct implementing `Default`. The struct is named `FooConfig`, `FooOptions`, or `FooParams`.
                  - Boolean parameters to public functions: forbidden. Replace with an enum. `fn process(input: &str, trim_whitespace: bool)` → `fn process(input: &str, whitespace: WhitespaceTreatment)`.
                  - `Option` parameters that are usually `None`: move them to a builder or configuration struct.

                  **Return types:**
                  - Sequence-producing functions: return `impl Iterator<Item = T>` instead of `Vec<T>`. Let the caller decide whether to collect.
                  - Exception: return `Vec<T>` when: (a) the function is `async`, (b) the entire sequence is computed eagerly anyway and the iterator would add overhead, (c) the collection is needed for multiple passes.
                  - `#[must_use]` on every constructor, builder terminal method, function returning `Result` or `Option`, and any function whose return value communicates important state. Add `#[must_use = "descriptive message"]` for non-obvious cases.

                  **Method placement:**
                  - Methods belong to their natural owner. A function that operates primarily on `T` is a method or associated function on `T`, not a free function.
                  - Free functions are for operations with no clear type affinity (utility algorithms, mathematical operations on multiple unrelated types).
                  - Methods that do not use `self` are associated functions (`fn foo() -> T`), not free functions.
                  - `impl` blocks are ordered: constructors first, then methods that return `&self` (readers), then methods that take `&mut self` (mutators), then methods that take `self` (consumers), then associated functions, then trait implementations.

                  ---

                  ### Closures

                  - Closures are for short, single-purpose operations in higher-order function contexts.
                  - Closures exceeding three lines: extract a named function and pass it by reference.
                  - Use the most permissive bound that is correct: `Fn` when no mutation, `FnMut` when mutation, `FnOnce` when ownership is transferred. Never constrain to `FnOnce` when `Fn` would work.
                  - `move` closures are required when the closure outlives its creation scope: stored in a struct, returned from a function, or sent to another thread.
                  - Named closures use descriptive names: `let is_eligible = |user: &User| user.age() >= MIN_AGE;` not `let f = |x| ...`.
                  - Method reference form when the closure is just a method call with no transformation: `.map(User::display_name)` not `.map(|user| user.display_name())`.
                  - Function reference form when the closure is just a function call: `.filter(is_valid_email)` not `.filter(|s| is_valid_email(s))`.
                  - `|| {}` — the unit-returning no-op closure — is acceptable only as a required stub.

                  ---

                  ### Struct Instantiation and Function Calls

                  - Never instantiate a struct inline as an argument to a function or nested inside `Ok(...)`, `Err(...)`, `Some(...)`, or `Box::new(...)`. Bind to a named variable first, then pass it.
                  - Wrong: `send_message(Message { recipient: user_id, content: text })`
                  - Right: `let message = Message::new(user_id, text); send_message(message)`
                  - Function calls on one line. Multi-line argument lists signal the function has too many parameters — introduce a configuration struct.
                  - Always `use` a type before using it. Never qualify at call sites when a `use` statement removes the qualification. `crate::auth::UserId::new(42)` → `use crate::auth::UserId; UserId::new(42)`.
                  - Inside `impl` blocks: use `Self` everywhere the implementing type would be named. `Self { field }` not `TypeName { field }`. `-> Self` not `-> TypeName`. `Self::new()` not `TypeName::new()`.
                  - Struct literal construction outside `impl TypeName` is forbidden. Every struct constructed externally has a `new()` or `try_new()` constructor. `Config { timeout: Duration::from_secs(30) }` outside `impl Config` is forbidden.
                  - Update syntax `..other` when constructing from an existing instance with modified fields. Document which fields are overridden.

                  ---

                  ### API Design

                  **Builder pattern:**
                  - Use a builder type when: more than four construction parameters, or parameters are optional, or construction can fail due to missing required parameters.
                  - `FooBuilder::new(required_param)` — required parameters are constructor arguments.
                  - Optional parameters are setter methods: `fn with_timeout(mut self, timeout: Duration) -> Self`.
                  - Terminal method: `fn build(self) -> Result<Foo, FooBuilderError>` when construction can fail.
                  - Terminal method: `fn build(self) -> Foo` only when all required parameters are in `new()` and all optionals have defaults.
                  - Builder type name: `FooBuilder` in the same file as `Foo`.

                  **API surface minimization:**
                  - Every public item is a commitment. Minimize the surface.
                  - `#[doc(hidden)]` to hide items that must be `pub` for macro or blanket-impl reasons but are not part of the intended API.
                  - Expose the minimum type information necessary. Return `impl Trait` instead of a concrete type when the concrete type is an implementation detail.

                  **No out-parameters:**
                  - Functions never use `&mut T` parameters to return computed values. Return a named struct.
                  - Exception: the established IO pattern `read(&mut self, buffer: &mut [u8]) -> Result<usize>` is a buffer fill, not an out-parameter.
                  - Exception: `fmt::Display::fmt(&self, f: &mut Formatter)` is standard library convention.

                  **Validation:**
                  - Validate all inputs at the public API boundary. Never accept invalid input and process it silently.
                  - Prefer static enforcement: newtypes and enums that make invalid values unrepresentable.
                  - Dynamic enforcement: validate in `try_new()` or `build()`, return a descriptive `Err` immediately.
                  - Never coerce invalid input into a valid-looking form silently (trimming unexpected characters, defaulting invalid numbers to 0).

                  **Destructors:**
                  - `impl Drop` must never panic. If the destructor can fail, provide a separate `fn close(self) -> Result<(), Error>` for explicit teardown. The `Drop` impl silently ignores or logs errors.
                  - `impl Drop` must never block the calling thread. Provide an async teardown method for async resources.
                  - Resources with explicit lifetimes use RAII: the resource is acquired in the constructor and released in `Drop`.

                  **Versioning:**
                  - `#[non_exhaustive]` on all public enums and structs to prevent downstream exhaustive matching or construction.
                  - Semver: breaking changes require a major version bump. Adding `#[non_exhaustive]` fields or variants is a minor change.
                  - Deprecate before removing: `#[deprecated(since = "1.2.0", note = "use new_method() instead")]`.

                  ---

                  ### Serialization (Serde)

                  - Types that cross serialization boundaries (REST API, database, config files, message queues) derive `Serialize` and `Deserialize`.
                  - Field names in serialized formats: use `#[serde(rename = "camelCase")]` or `#[serde(rename_all = "camelCase")]` for JSON APIs. Never change the Rust field name convention to match the wire format.
                  - `#[serde(default)]` when a field may be absent in older serialized data. The `Default` impl provides the fallback value.
                  - `#[serde(skip_serializing_if = "Option::is_none")]` for optional fields that should be omitted from output when absent.
                  - `#[serde(flatten)]` to inline a struct's fields into its parent. Use sparingly; it makes the wire format harder to reason about.
                  - `#[serde(deny_unknown_fields)]` on input types to fail fast on unexpected fields (prevents silent data loss from schema drift).
                  - Never derive `Deserialize` on a type with complex invariants without a custom `Deserialize` impl that validates those invariants. Using `#[serde(try_from = "RawType")]` with a `TryFrom` impl is the correct pattern.
                  - Custom serializers and deserializers: use `#[serde(with = "module")]` pointing to a module with `serialize` and `deserialize` functions. Never implement `Serialize` / `Deserialize` manually unless `#[serde(with = ...)]` is insufficient.
                  - `serde_json::Value` in domain types: forbidden. Deserialize to typed structures at the boundary.

                  ---

                  ### Configuration

                  - Configuration is loaded once at startup, validated completely, and stored in an immutable struct.
                  - Configuration types derive `Debug`, `Clone`. They do NOT derive `Serialize` — configuration is input only.
                  - Every configuration field has a documented default and valid range in the doc comment.
                  - Invalid configuration (missing required field, out-of-range value) causes the program to exit at startup with a descriptive error. A misconfigured program that starts and then fails at runtime is incorrect.
                  - Environment variables are read in one place: the configuration loading function. Business logic never calls `std::env::var()`.
                  - Configuration structs are validated with a `validate(&self) -> Result<(), ConfigError>` method that is called immediately after deserialization. All invariants are checked: positive values are positive, durations are non-zero, paths exist.
                  - `dotenvy` for `.env` file loading in development. Config sources: environment variables override config file values. Document the priority order.

                  ---

                  ### Logging and Tracing

                  **Use `tracing`, not `log`:**
                  - All instrumentation uses the `tracing` crate. `println!`, `eprintln!`, `log::info!` — all forbidden in application code.
                  - The `log` crate is only used transitively via `tracing-log` for compatibility with third-party crates.

                  **Span and event levels:**
                  - `tracing::error!` — a situation that requires immediate attention; the operation cannot continue. Examples: failed to bind to port, database connection pool exhausted.
                  - `tracing::warn!` — a situation that is unexpected but the operation can continue. Examples: retrying after a transient failure, deprecated API used.
                  - `tracing::info!` — a significant lifecycle event at coarse granularity. Examples: server started, request completed, background job finished.
                  - `tracing::debug!` — information useful for diagnosing problems in a specific subsystem. Examples: HTTP request/response details, cache hit/miss.
                  - `tracing::trace!` — very detailed low-level information; disabled in production. Examples: lock acquisition/release, individual message processing steps.

                  **Structured fields:**
                  - Every `tracing!` event includes structured key-value fields, not interpolated strings.
                  - Wrong: `tracing::info!("User {} logged in from {}", user_id, ip_address)`.
                  - Right: `tracing::info!(user_id = %user_id, ip_address = %ip_address, "user logged in")`.
                  - Use `%` for `Display`, `?` for `Debug`, no sigil for primitives and types implementing `tracing::Value`.
                  - Field names: `snake_case`, descriptive. `user_id`, `request_duration_ms`, `error_code`.
                  - Never log sensitive data (passwords, tokens, PII) at any level.

                  **Spans:**
                  - Every async task, request handler, and significant background operation is wrapped in a `tracing::Span`.
                  - Spans are created with `tracing::info_span!("operation_name", field = value)`.
                  - Async functions are instrumented with `#[tracing::instrument]` when span creation must be automatic.
                  - `#[tracing::instrument(skip(password, token))]` to exclude sensitive parameters from the span.
                  - Spans are entered with `.in_scope(|| ...)` for synchronous code and `.instrument(future)` for async.

                  ---

                  ### Testing

                  **Unit tests:**
                  - `#[cfg(test)] mod tests { use super::*; }` at the bottom of every file under test.
                  - `mod tests` begins with `use super::*`, then any additional explicit imports. No other items before `use super::*`.
                  - Every public function: at least one test for the primary (happy) path and at least one test for each failure mode.
                  - Test names: full scenario descriptions in `snake_case`. `returns_error_when_email_is_empty`, `increments_retry_count_on_transient_failure`, `parses_valid_iso8601_timestamp`. Never `test1`, `it_works`, `test_foo`, `basic`, `works`, `test`.
                  - `#[should_panic]` is forbidden. Use `assert!(result.is_err())` and inspect the error variant.
                  - Test functions that call fallible code return `Result<(), Error>`. Using `unwrap()` in a test is forbidden.
                  - `println!`, `eprintln!`, `dbg!` are forbidden in tests (output is captured but clutters test runs).
                  - `assert_eq!(actual, expected)` — actual value first, expected value second. Failure message shows both. Never `assert!(a == b)`.
                  - `assert_ne!(actual, unexpected)`. Never `assert!(a != b)`.
                  - `assert!(condition, "descriptive message with {}", context)` for boolean conditions that require context.
                  - Test helpers are private functions in `mod tests`. They do not exist at the module level.
                  - Magic test values are named `const`: `const VALID_EMAIL: &str = "user@example.com"` not the bare string.
                  - Tests are deterministic. No random data without a seeded RNG. No time-dependent logic without a mockable clock.
                  - `#[ignore]` on slow tests that should not run on every `cargo test`. Mark with a comment explaining why they are slow.

                  **Integration tests:**
                  - `tests/` at the crate root. Each file is a separate integration test binary with its own compilation unit.
                  - Integration tests exercise the public API only. Never `use crate::internal_module`.
                  - Each file begins with a `//!` comment describing what scenario or feature it covers.
                  - Test database, test server, and external service mocking is set up in a shared `tests/common/mod.rs` module.

                  **Property-based tests:**
                  - Use `proptest` for functions with large, combinatorial, or unclear input spaces.
                  - Property tests live in the same `mod tests` block using the `proptest!` macro.
                  - Every newtype's `mod tests` defines a proptest `Strategy` for generating valid instances. This strategy is used in all property tests that need the newtype.
                  - Property test names describe the invariant being tested: `parsed_output_roundtrips_through_display`.

                  **Benchmarks:**
                  - `benches/` using `criterion`. Never `#[bench]` (requires nightly).
                  - Each benchmark has a `// what: <what is being measured>` and `// complexity: <expected big-O>` comment.
                  - Benchmarks are run before and after performance-affecting changes. Results are noted in the commit.
                  - `criterion::black_box` prevents the optimizer from eliding the benchmarked code.

                  **Test data builders:**
                  - Complex types needed in multiple tests have a `TestBuilder` (in test code only: `#[cfg(test)]`).
                  - `FooTestBuilder` has `Default`-like construction with valid test defaults and setter methods. Named `FooTestBuilder::default().with_email("test@example.com").build()`.
                  - Test builders are in `mod tests` or in a `tests/common/` module, never in production code.

                  **Doc tests:**
                  - Every `# Examples` section compiles and runs correctly.
                  - Doc test examples use `?` for error propagation with `fn main() -> Result<(), Box<dyn std::error::Error>>`.
                  - Doc tests never call `unwrap()`. The example code must be idiomatic.
                  - `# Examples` sections test the primary use case, not edge cases. Edge cases go in unit tests.

                  ---

                  ### Async

                  - Every `async fn` performing IO has a `// awaits: <what it awaits>` doc comment or a `# Awaits` section.
                  - `std::thread::sleep` in async code: forbidden. Use `tokio::time::sleep`.
                  - Synchronous IO (`std::fs::read`, `std::net::TcpStream`) in async code: forbidden. Use `tokio::fs::read`, `tokio::net::TcpStream`, or `tokio::task::spawn_blocking` with a `// blocking: <reason>` comment.
                  - `tokio::spawn` tasks: always `await`ed, or the `JoinHandle` is stored and joined, or the task is added to a `JoinSet`. Fire-and-forget spawning is forbidden unless the task's unobserved termination is explicitly documented.
                  - `std::sync::Mutex` guard held across `.await`: forbidden. Use `tokio::sync::Mutex` or explicitly drop the guard before `.await`.
                  - Lock guard scoping: `{ let guard = lock.lock().await; /* use guard */ } /* guard dropped before .await */`.
                  - `#[tokio::main]`: always `flavor = "multi_thread"` unless single-threaded is justified in a comment. `worker_threads` is set explicitly when the count matters.
                  - `async fn` that neither calls `.await` on anything nor delegates to other `async fn`s: remove the `async` keyword. It creates a future with unnecessary overhead.
                  - Async trait methods: use the `async-trait` crate or `impl Trait` return types (`-> impl Future<Output = T>`). Document which pattern is used and why.
                  - Cancellation safety: every `tokio::select!` branch that calls a `.await` point inside a non-cancellation-safe future must hold the future across loop iterations. Document cancellation safety in `// cancellation-safe: <yes/no, reason>` on `async fn` that are used in `select!`.
                  - Timeout all network operations: `tokio::time::timeout(OPERATION_TIMEOUT, operation).await` or set timeouts on the underlying connection. Never allow unbounded waits.
                  - `tokio::sync::oneshot` for single-value communication between tasks. `tokio::sync::mpsc` for streams. `tokio::sync::watch` for shared state updates. `tokio::sync::broadcast` for fan-out.
                  - Backpressure: bounded channels. Never unbounded channels in production code. Every `mpsc::channel(CAPACITY)` has its capacity documented: `// capacity: limits in-flight commands to N to prevent unbounded memory growth`.

                  ---

                  ### Safety

                  - `unsafe` is forbidden except when the operation is genuinely impossible in safe Rust and the crate's explicit purpose is providing a safe wrapper.
                  - Every `unsafe` block is immediately preceded by a `// SAFETY:` comment that: (a) names the safety invariant being upheld, (b) explains why the invariant holds at this specific call site, and (c) names any caller preconditions.
                  - `// SAFETY:` comments are not optional. An `unsafe` block without a `// SAFETY:` comment is a build failure in code review.
                  - `std::mem::transmute`: forbidden.
                  - `std::mem::forget`: forbidden in code that manages resources. Document if used.
                  - Direct `std::ptr::*` operations: forbidden outside a crate whose explicit, stated purpose is providing a safe abstraction over unsafe primitives.
                  - `unsafe impl Send` and `unsafe impl Sync`: each requires a `// SAFETY:` comment explaining the thread-safety invariant. Common patterns: wrapping a raw pointer that is never aliased across threads, wrapping a type with only atomic operations.
                  - Every `unsafe fn` in the public API has a `# Safety` section in its doc comment listing ALL caller preconditions — not one missing.
                  - FFI: all C function calls are wrapped in a safe Rust function that validates preconditions. The raw `extern "C"` functions are never exposed in the public API.
                  - `#[no_mangle]` and `extern "C"` functions: clearly documented as FFI exports.

                  ---

                  ### Macros

                  **When to write a macro:**
                  - Macros are a last resort. Write a function first. If a function cannot express the required behavior (variadic arguments, syntax patterns, compile-time code generation), then write a macro.
                  - Never write a macro because it saves typing. If it saves typing for the caller but adds maintenance complexity, it is a net negative.
                  - Never write a macro to abstract over item definitions (struct fields, trait impls) when `proc_macro_derive` would be more appropriate and discoverable.

                  **Declarative macros (`macro_rules!`):**
                  - Used for simple textual pattern matching and expansion.
                  - Every macro has a doc comment explaining its purpose and showing an example.
                  - Macros are `#[macro_export]` only when they are part of the public API. Internal macros are not exported.
                  - Macro rules are listed from most specific to least specific. The first matching rule wins.
                  - `macro_rules!` hygiene: use `$crate::` to refer to items in the defining crate, not bare paths. This prevents name collisions in user code.
                  - Macros that expand to statements inside blocks use `$(...)*` or `$(...)+` for repetition. Never manually repeat expansion arms for different arities.

                  **Procedural macros:**
                  - `derive` macros for automatically implementing traits on structs and enums.
                  - `attribute` macros for transforming function signatures or adding boilerplate.
                  - Procedural macros live in a separate crate with the `-macros` suffix: `my-crate-macros`.
                  - Every procedural macro generates correct Rust code that passes `rustfmt` when formatted.
                  - Proc macro errors: use `syn::Error::new(span, message)` to emit errors at the correct source location.

                  **Macro hygiene:**
                  - Never introduce bindings that shadow caller variables. Use `let $name = ...` only when the binding name is controlled by the caller.
                  - Emit identifiers with `quote::format_ident!` not string concatenation.
                  - Test proc macros with `trybuild` for compile-error cases.

                  ---

                  ### Derives and Attributes

                  - Derive order (fixed sequence, include only what is needed for the type):
                    `#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, Serialize, Deserialize)]`
                  - Every struct and enum derives `Debug`. No exceptions.
                  - `#[allow(...)]` at file or module level: forbidden. Apply to specific items only, with an immediately preceding comment explaining why the lint does not apply here.
                  - `#[allow(dead_code)]` on non-enum items: forbidden. Delete dead code.
                  - `#[allow(dead_code)]` on enum types: acceptable when all variants are part of the public API surface but not yet exercised in this crate.
                  - `#[allow(clippy::too_many_arguments)]`: forbidden. Reduce the argument count by introducing a configuration struct.
                  - `#[allow(clippy::cognitive_complexity)]`: forbidden. Reduce complexity by splitting the function.
                  - `#[derive(Copy)]` requires an adjacent comment: `// Copy: no heap resources; value semantics are correct for this type.`
                  - `#[must_use]` on every constructor, every builder terminal method, every function returning `Result`, every function returning `Option`.
                  - `#[must_use = "if this result is not checked, errors are silently ignored"]` — add the message string to `#[must_use]` on `Result`-returning functions for clarity.
                  - `#[cfg(test)]` on the `mod tests` block, not on individual test functions.
                  - `#[doc(hidden)]` for items that must be `pub` for technical reasons (macro expansion, blanket impls) but are not part of the intended public API.
                  - `#[non_exhaustive]` on all public enums and public structs to allow adding variants/fields in minor versions without breaking downstream.
                  - `#[cold]` on functions that are on the cold path (error handling, panics, rare code). Helps the optimizer understand branch prediction.
                  - `#[inline]` guidance: on small functions called across crate boundaries in hot paths. `#[inline(always)]` only when a benchmark proves necessity. `#[inline(never)]` on cold paths to keep hot-path instruction cache clean.

                  ---

                  ### Performance and Zero-Cost Abstractions

                  **Allocation discipline:**
                  - Every heap allocation is visible and explicit at the call site: `Box::new(...)`, `Vec::new()`, `String::new()`, `Arc::new(...)`.
                  - Allocations in hot paths (per-request, per-frame, per-packet code) require a comment: `// alloc: necessary because <reason this specific allocation cannot be avoided>`.
                  - Prefer stack-allocated data. Use `Vec<T>` only when the size is not known at compile time. Use `[T; N]` for fixed-size collections.
                  - Avoid `Vec<Box<dyn Trait>>` for homogeneous collections. Use `Vec<ConcreteType>` directly. Dynamic dispatch is only for heterogeneous collections.
                  - `String::with_capacity(estimated_length)` before string building loops. `format!` allocates on each call — avoid it in loops.
                  - Measure before optimizing. A comment that says "this is fast" without a benchmark is not evidence.

                  **Generic functions — zero-cost dispatch:**
                  - A generic function `fn foo<T: Trait>(value: T)` generates specialized machine code per type — zero runtime overhead.
                  - `fn foo(value: &dyn Trait)` generates one code path with a vtable call on every method — runtime overhead.
                  - Use generics for performance-critical paths. Use `dyn Trait` only when the concrete type is genuinely unknown at compile time or a heterogeneous runtime collection is needed.

                  **`#[inline]` guidance:**
                  - `#[inline]` on small functions (1-5 lines) called across crate boundaries in hot paths.
                  - `#[inline(always)]` is rare. Requires a benchmark. Never speculative.
                  - `#[inline(never)]` on cold paths (error construction, rare branches) to prevent them from polluting the hot path's instruction cache footprint.

                  **Struct layout optimization:**
                  - Order struct fields from largest alignment to smallest alignment to minimize internal padding.
                  - Example: `{ field_a: u64, field_b: u32, field_c: u16, field_d: u8 }` — not `{ field_b: u32, field_d: u8, field_a: u64, field_c: u16 }`.
                  - Group fields that are accessed together in the same cache line.
                  - `PhantomData<T>` and zero-sized marker fields at the end, after all data fields.
                  - Run `cargo clippy -- -W clippy::pedantic` periodically to catch struct padding issues.

                  **Data structure selection — one right choice per access pattern:**
                  - `Vec<T>` — ordered sequence, random access by index, append-only or full replacement.
                  - `VecDeque<T>` — double-ended queue: push/pop at both ends efficiently.
                  - `HashMap<K, V>` — unordered key-value lookup with O(1) amortized. Default hasher is `RandomState` (SipHash). Use `rustc-hash::FxHashMap` for performance-critical small-key maps after benchmarking.
                  - `BTreeMap<K, V>` — ordered key-value lookup with O(log n). When sorted iteration is required, when range queries (`range()`) are needed, when deterministic iteration order matters.
                  - `HashSet<T>` — O(1) membership testing.
                  - `BTreeSet<T>` — sorted set, O(log n) membership.
                  - `[T; N]` — fixed-size, stack-allocated array when N is known at compile time.
                  - `SmallVec<[T; N]>` (from `smallvec` crate) — Vec-like type that stores up to N elements on the stack, spills to heap only when exceeded. Use when arrays are usually small but occasionally large.
                  - `LinkedList<T>` — never. Cache performance is almost universally worse than `Vec<T>`. The only case where a linked list is correct is when `O(1)` splice operations on the list itself are needed.
                  - `.contains(&item)` on `Vec<T>` is O(n). If membership testing is a use case, the data structure must be `HashSet<T>` or `BTreeSet<T>`.

                  **Avoiding unnecessary clones:**
                  - A `.clone()` on a non-trivial type in a hot path is a code smell requiring a benchmark to justify.
                  - `Cow<'a, T>` (Clone-on-Write) for data that is usually borrowed but sometimes needs to be owned: avoids allocation in the common case.
                  - `Arc<T>` for shared read-only data that must outlive multiple owners: one allocation, many cheap clones.

                  ---

                  ### Documentation and ARCHITECTURE.md

                  **ARCHITECTURE.md at workspace root — mandatory:**
                  - What the system does: one paragraph of plain English, no jargon.
                  - Crate-level map: each crate on one line. Format: `- crates/name/ — responsibility (depends on: crate-a, crate-b)`.
                  - Data flow diagram: ASCII art or prose describing how data enters (HTTP, CLI, file), is transformed (parse, validate, enrich, persist), and exits (response, output, side effect).
                  - Key cross-crate invariants: the contracts every crate assumes. "The auth crate guarantees that SessionToken values have been validated against the database before being returned."
                  - Entry points: the binary's `main()` function path. Where the tokio runtime starts. Where the first request is received.
                  - External systems: databases, queues, external APIs, and which crate(s) own the integration.
                  - Update this document when the architecture changes. Stale documentation is misinformation.

                  **Module-level documentation:**
                  - Every `mod.rs` file begins with a `//!` inner documentation comment.
                  - The `//!` comment states: what types or functionality the module contains (one sentence), why this module exists as a separate boundary (one sentence), and which other modules it depends on (if non-obvious).

                  **Item documentation:**
                  - Every `pub` item (struct, enum, function, trait, constant, type alias) has a `///` doc comment.
                  - First line: a one-line summary in third person imperative. `/// Authenticates a user using the provided credentials.`
                  - Doc comments do not begin with the item name: `/// A user account` not `/// User represents a user account`.
                  - `# Examples` section for every public function with non-obvious usage. The example compiles and passes as a doc test.
                  - `# Errors` section listing every `Err` variant the function can return and the conditions that cause it.
                  - `# Panics` section if the function can panic under any condition. If it cannot panic, no section needed.
                  - `# Safety` section on every `unsafe fn` listing all caller preconditions.
                  - `# Invariants` section on struct types with non-trivial invariants.

                  ---

                  ### Code Organisation

                  - Functions and methods belong to their natural owner. A function that operates on a `User` is a method on `User`, not a free function `fn process_user(user: &User)`.
                  - No section-divider comments (`// === Helpers ===`, `// --- Private ---`, `// SECTION: constructors`). If a file needs visual sections, split it into submodules.
                  - No backwards-compatibility shims: removed items are deleted entirely. No `#[deprecated]` without a removal plan.
                  - No `TODO`, `FIXME`, `HACK`, `XXX`, or `TEMP` in committed code. File a GitHub issue and reference its number in a comment if tracking is needed: `// see issue #123`.
                  - `main.rs` contains only: CLI argument parsing (using `clap`), configuration loading and validation, tracing subscriber setup, tokio runtime setup, one call into the library's entry point, top-level error reporting.
                  - Domain-centric directory structure: `crates/auth/`, `crates/billing/`, `crates/notification/` — not `crates/models/`, `crates/handlers/`, `crates/services/`, `crates/repositories/`.
                  - Implementation details are never leaked through the module system. A type `pub` in a submodule but not re-exported from `lib.rs` is internal. If a user of the crate cannot construct, match, or name a type without accessing unexported paths, it is correctly hidden.
                  - Dead code is deleted. Never kept "in case it's needed." Version control preserves history.

                  ---

                  ### Abstraction Decisions

                  **When to abstract:**
                  - Abstract only when a concrete problem exists today, not hypothetically.
                  - Rule of three: do not extract a trait, generic function, or helper until the third concrete case arrives. Two cases may be coincidental similarity.
                  - Prefer duplication over a wrong abstraction. Wrong abstractions are harder to undo than duplicated code. Premature abstraction creates coupling across cases that may later need to diverge.
                  - Never "future-proof" with abstraction layers that have no current consumer.
                  - The test: can you name the abstraction in terms of what it does, not in terms of where it is used? `Validator` is a real abstraction. `AuthAndBillingHelper` is not.

                  **Traits are the unit of abstraction — abstract behavior, not structure:**
                  - Abstract what something does, not what it is.
                  - Data structures are concrete. Interfaces (traits) are abstract.
                  - A trait with one implementer today is acceptable only if it is a deliberate design for testability (swapping a real implementation with a test double). Document this: `// testability: allows mocking in tests`.
                  - A trait with one implementer that is not for testability is complexity without benefit — delete it.

                  **`impl Trait` vs. `dyn Trait` vs. `<T: Trait>`:**
                  - `impl Trait` (argument): single-trait bound; the concrete type is known at compile time and monomorphized.
                  - `<T: Trait>` (named generic): when you need to refer to `T` by name (in the return type, multiple parameters, or the body).
                  - `dyn Trait`: the concrete type is unknown at compile time, or a heterogeneous collection of types implementing `Trait` is needed.
                  - Never `Box<dyn Trait>` to avoid naming a type. The cost: one heap allocation plus one vtable indirection on every call.

                  **When to create a new crate vs. a new module:**
                  - New module: the code is an internal implementation detail, does not need independent versioning, and depends on internal types of the parent crate.
                  - New crate: the component has a clean, stable public interface; is independently useful to downstream crates; has different compilation requirements; or has a different release cadence.
                  - When in doubt: stay in the same crate. Premature crate splitting is premature abstraction at the package level.

                  **Dependency injection in Rust:**
                  - Avoid dependency injection frameworks. Rust's type system makes framework-based DI unnecessary.
                  - Pass dependencies as generic parameters or trait objects to constructors: `fn new<Database: UserDatabase>(database: Database) -> Self`.
                  - Application startup constructs all dependencies and wires them together in `main()`. Business logic never calls `new()` on its dependencies.
                  - Testability: pass a test double implementing the same trait in tests. No mocking framework needed.

                  ---

                  ### Formatting and Linting

                  - All Rust code passes `rustfmt` before the task is done. Use `cargo fmt` to format.
                  - All Rust code passes `cargo clippy --all-targets -- -D warnings` before the task is done.
                  - Run both tools after every edit.
                  - `rustfmt.toml` at the workspace root configures formatting. The configuration is committed and shared. The most common settings: `edition = "2021"`, `imports_granularity = "Crate"`, `group_imports = "StdExternalCrate"`.
                  - `clippy.toml` or `.clippy.toml` for workspace-level clippy configuration. Enable `clippy::pedantic` group as a warning (not an error) and disable individual pedantic lints that are incorrect for the codebase, with comments explaining each disable.
                  - Never silence a lint with `#[allow]` without understanding why the lint fired. The lint is almost always correct.
                  - `cargo deny` for license and dependency auditing. Run in CI. `deny.toml` at workspace root.
                  - `cargo audit` for security vulnerability scanning. Run in CI on every PR.
                  - `cargo doc --no-deps --all-features` must produce zero warnings. Documentation warnings are build failures.

                  ---

                  ### Naming Deep Reference

                  **File names:**
                  - Module files: `snake_case/mod.rs`. Never `snake_case.rs`. Never mixed case in directory names.
                  - Integration test files: `tests/snake_case_scenario.rs`. Full descriptive name of the scenario covered.
                  - Benchmark files: `benches/snake_case_what_is_benchmarked.rs`.
                  - Example files: `examples/kebab-case-use-case.rs`. Hyphenated like binary crate names.
                  - Build script: always `build.rs`. Never `build_script.rs` or `compile.rs`.

                  **Struct field names:**
                  - Fields named for semantic content, not the type: `created_at: Instant` not `instant: Instant`.
                  - When a struct has IDs for multiple entity types: qualify the field name. `author_id: UserId`, `post_id: PostId` — not both named `id`.
                  - Timestamp fields: `created_at`, `updated_at`, `deleted_at`, `expires_at`, `started_at`, `ended_at`. The `_at` suffix signals a point in time.
                  - Duration fields: `timeout`, `retry_interval`, `session_duration`. When units are ambiguous: `timeout_seconds` or use a newtype `Seconds { value: u64 }`.
                  - Count fields: `retry_count`, `connection_count`, `failure_count`. The `_count` suffix signals a cardinal number. Never `retries` (ambiguous: a count or a collection?).
                  - Size fields: `buffer_size`, `chunk_size`, `page_size`, `pool_size`. Include units in the name when the unit is not bytes.
                  - Boolean fields: predicate form only. `is_enabled`, `has_errors`, `was_migrated`, `can_reconnect`. Never bare adjectives `enabled`, `migrated`, `active`.

                  **Enum variant naming:**
                  - State variants: present-tense noun or adjective. `Connected`, `Disconnected`, `Pending`, `Active`, `Expired`, `Cancelled`, `Failed`, `Succeeded`.
                  - Error variants: noun phrase describing the condition. `InvalidInput`, `ConnectionTimeout`, `PermissionDenied`, `NotFound`, `AlreadyExists`.
                  - Event variants: past-tense verb phrase. `UserCreated`, `OrderPlaced`, `PaymentProcessed`, `SessionExpired`.
                  - Command variants: imperative verb phrase. `CreateUser`, `PlaceOrder`, `ProcessPayment`, `ExpireSession`.
                  - Variants never start with the enum name: `Status::Active` not `Status::StatusActive`. `Color::Red` not `Color::ColorRed`.
                  - Never use `Other`, `Unknown`, `Misc`, or `Custom` as a catch-all variant unless the domain genuinely has an open-ended category.

                  **Trait names:**
                  - Capability traits: gerund or agent noun. `Serialize`, `Deserialize`, `Read`, `Write`, `Display`, `Debug`, `Clone`, `Iterator`, `Hasher`, `Executor`.
                  - Property traits: adjective. `Send`, `Sync`, `Sized`, `Unpin`, `Copy`.
                  - Domain interface traits: noun phrase. `UserRepository`, `EmailSender`, `PaymentProcessor`, `MessageQueue`.
                  - Never prefix with `I`: `IRepository` is Java. `Repository` is Rust.
                  - Never suffix with `Trait`: `SerializableTrait` is forbidden. `Serializable` is correct.
                  - Never suffix with `able` unless the word is standard English: `Serializable` is fine. `Processable` and `Handleable` are not words — use `Process` and `Handle`.

                  **Function parameter names:**
                  - Name the role, not the type: `recipient: &User` when the user receives something. `requester: &User` when the user makes a request. Not just `user: &User` when the role matters.
                  - Never single-letter parameters except `self`.
                  - Never type-echoing names: `string: &str`, `vec: &[T]`. Name what it represents: `email: &str`, `items: &[Item]`.
                  - Callback parameters: descriptive. `on_success`, `on_error`, `handle_event`, `transform`, `predicate`. Never `f`, `cb`, `func`.

                  **Const and static names:**
                  - Named for domain meaning with units: `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_SECONDS`, `MAX_PAYLOAD_BYTES`, `MIN_PASSWORD_LENGTH`, `BCRYPT_COST_FACTOR`.
                  - Never named for value: `ZERO`, `ONE`, `HUNDRED`, `EMPTY`. These communicate nothing.
                  - Bit masks: named for what they mask. `READ_PERMISSION_BIT`, `WRITE_PERMISSION_BIT`. Never `BIT_0`, `FLAG_1`.
                  - `const` preferred over `static` for compile-time values. Use `static` only when the address identity matters or the type is not `const`-initializable.

                  ---

                  ### Struct Design Deep Reference

                  **Invariants and field visibility:**
                  - A struct whose constructor stores parameters without validation has no invariants. Its fields may be `pub`. Document: `// invariants: none; plain data struct`.
                  - A struct whose constructor validates parameters has invariants. Its fields are private without exception.
                  - Document invariants in a `# Invariants` section in the struct doc comment. Every property guaranteed for all instances constructed via the public API.
                  - Accessor methods for private fields: one method per field, named exactly the field name. `fn id(&self) -> UserId` not `fn get_id(&self) -> UserId`. Return `FieldType` for `Copy` types, `&FieldType` for non-`Copy` types.
                  - Mutable accessor (setter): `fn set_field(&mut self, value: FieldType)`. When a setter validates its input, return `Result<(), Error>`.
                  - Structs with no meaningful default state do not implement `Default`. Forcing a "default" value when no natural zero exists is a code smell.
                  - Structs representing handles or contexts (`DatabaseConnection`, `FileHandle`, `NetworkSocket`) implement `Drop` to release the resource.
                  - Structs that implement `Drop` do not also implement `Clone` unless the clone increments a reference count (wrapping `Arc`).
                  - Generic structs with `PhantomData<T>`: the `PhantomData` field is listed last, after all real data fields.

                  **Struct size:**
                  - A struct with more than 8 fields is a smell. Consider whether some fields form a coherent sub-concept.
                  - A struct where more than half the fields are `Option` is always wrong. Those `Option`s form an implicit enum — make it explicit.
                  - A struct that changes identity at runtime (user becomes admin) is not a single struct. Use an enum or type-state.
                  - Request/response structs for HTTP or RPC are separate from domain structs. Never reuse a domain struct as a wire type. Parse the wire format into domain types immediately at the boundary.

                  **Constructor patterns:**
                  - `fn new(params) -> Self` — infallible. All parameters valid by type.
                  - `fn try_new(params) -> Result<Self, Error>` — fallible. Parameters require validation.
                  - `fn default() -> Self` via `#[derive(Default)]` when all fields have meaningful defaults. Never implement `Default` manually when derive produces the same result.
                  - Never `new()` that can panic. If construction can fail, return `Result`.
                  - Named constructors beyond `new()` only for established domain vocabulary: `open`, `connect`, `bind`, `spawn`, `parse`, `decode`, `from_file`, `from_env`.

                  ---

                  ### Enum Design Deep Reference

                  **Variant data decision tree:**
                  - No data: unit variant without parentheses. `Pending`, `Active`, `Expired`.
                  - One unambiguous wrapped type: single-element tuple variant. `Failed(IoError)`. This is the only acceptable tuple variant.
                  - Two or more values: named-field variant. `Move { x: i32, y: i32 }`. Never positional tuple variant with two or more fields.
                  - Wrapped errors: one source type per variant. Never `Other(Box<dyn Error>)`.

                  **Enum completeness:**
                  - Public enums that may gain variants: `#[non_exhaustive]`.
                  - Internal enums with unused variants: `#[allow(dead_code)]` on the enum type, not individual variants.
                  - Every variant exercised in tests or removed.

                  **Enum methods:**
                  - Predicate per state: `fn is_active(&self) -> bool`, `fn is_expired(&self) -> bool`.
                  - Accessor for variant data: `fn as_error(&self) -> Option<&Error>`. Returns `Option` because the variant may not be present.
                  - Callers use methods. Callers do not `match` on enum internals when a method exists.
                  - `match` arms over 3 lines: extract a function. Nested `match`: extract a method on the inner type.

                  ---

                  ### Error Handling Deep Reference

                  **Error type design:**
                  - Every library crate has exactly one top-level error enum. All errors are variants of this enum, directly or nested.
                  - No error variants carry `String` as the primary field. Error variants carry typed data. The `String` may be input that caused the error, never the error description.
                  - `thiserror` is the only error derivation library. Never `quick-error` or manual `impl Error`.
                  - Every `#[error("...")]` string is correct English, lowercase, no trailing period, describes the condition from the user's perspective.
                  - Never `"error: ..."` in an `#[error]` string — the calling context adds that.
                  - `Display` on an error type describes the error for logging. Never restates the error type name.
                  - No `Other(String)` catch-all variant. Every error condition is a named variant.
                  - Error types implement `Send + Sync + 'static` so they work with `anyhow` and across threads.

                  **Error propagation:**
                  - `?` always. Never explicit `match` to re-wrap errors.
                  - Type mismatch: implement `From<SourceError> for TargetError`. `?` uses it automatically.
                  - Discarding errors: `let _ = op();` is forbidden. Use `if let Err(error) = op() { tracing::warn!(...); }` for non-fatal errors.
                  - Never log before propagating. Log at the handling site.

                  **Error recovery patterns:**
                  - Retry logic: max retries and delay are configurable constants. The retry loop is a named function. Retried errors logged at `debug`. Final failure logged at `error` and propagated.
                  - Partial failure in batch operations: `Vec<Result<T, E>>` or a `BatchResult<T, E>` struct. Never abort the entire batch on the first error unless atomicity is required.
                  - Circuit breaker: a named struct with an enum state field (`Closed`, `Open`, `HalfOpen`). Thresholds are configurable constants.

                  ---

                  ### Trait Design Deep Reference

                  **Trait method design:**
                  - Methods that cannot have a reasonable default implementation: no default body.
                  - Methods with a reasonable default: provide a default body. The default is always correct, never `todo!()` or `unimplemented!()`.
                  - Traits with one required method and many defaults: this is the correct Rust pattern. `Iterator` is canonical — only `next()` required.
                  - A trait with ten or more required methods: either combining multiple concerns (split it) or should be a concrete type.
                  - Associated types vs. generic parameters: use an associated type when there is exactly one natural output type per implementing type. Use a generic parameter when a type might implement the trait for multiple type arguments.

                  **Trait coherence:**
                  - Implement a trait for a type only if you own the trait OR you own the type.
                  - Blanket implementations only in the crate that defines the trait.
                  - Before writing a blanket impl, verify it does not conflict with standard library blanket impls.

                  **Object safety:**
                  - A trait intended for `dyn` usage must be object-safe: no methods returning `Self`, no generic methods.
                  - Methods that cannot be object-safe: `where Self: Sized` to exclude from the vtable.
                  - Document: `/// This trait is object-safe and can be used as a trait object.`

                  **Implementing external traits:**
                  - Implement all applicable standard library traits: `Debug`, `Display`, `Clone`, `PartialEq`, `Eq`, `Hash`, `PartialOrd`, `Ord`, `Default`, `From`, `TryFrom`, `AsRef`, `Borrow`, `FromStr`, `Iterator`, `IntoIterator`.
                  - `From<T>` for every lossless input representation.
                  - `AsRef<str>` on string newtypes so they work with `impl AsRef<str>` parameters.
                  - `Borrow<str>` on string newtypes so they work as `HashMap` keys queried by `&str`.
                  - `Deref<Target = str>` on string newtypes only when all `str` operations are semantically valid on the newtype. Never for semantic types where string operations must be controlled.

                  ---

                  ### Iterator Deep Reference

                  **Implementing `Iterator`:**
                  - `fn size_hint(&self) -> (usize, Option<usize>)` whenever size is known or bounded. Enables pre-allocation in `collect`.
                  - `fn count(self) -> usize` overridden when counting without consuming all elements is possible.
                  - `fn nth(&mut self, n: usize) -> Option<Self::Item>` overridden for random-access iterators.
                  - `DoubleEndedIterator` when both forward and reverse traversal is meaningful.
                  - `ExactSizeIterator` when the exact length is always known. Requires correct `size_hint()`.
                  - `FusedIterator` (empty marker impl) when the iterator reliably returns `None` forever after the first `None`.

                  **Providing iteration:**
                  - `iter(&self) -> Iter<'_>` — yields `&Element`.
                  - `iter_mut(&mut self) -> IterMut<'_>` — yields `&mut Element`.
                  - `impl IntoIterator for Type` — consumes, yields `Element`.
                  - `impl IntoIterator for &Type` — delegates to `iter()`.
                  - `impl IntoIterator for &mut Type` — delegates to `iter_mut()`.

                  **Adapter reference:**
                  - `.map(f)` — transform every element.
                  - `.filter(p)` — keep matching elements.
                  - `.filter_map(f)` — transform and filter; `f` returns `Option`. Never `.filter().map()` when this achieves the same.
                  - `.flat_map(f)` — transform each element to an iterator and chain.
                  - `.flatten()` — unwrap one level of nesting.
                  - `.take(n)` / `.skip(n)` — limit or skip.
                  - `.take_while(p)` / `.skip_while(p)` — conditional limit/skip.
                  - `.enumerate()` — pair with 0-based index.
                  - `.zip(other)` — pair elements from two iterators; stops at shorter.
                  - `.unzip()` — split pairs into two collections.
                  - `.chain(other)` — concatenate two iterators.
                  - `.peekable()` — look-ahead without consuming.
                  - `.rev()` — reverse; requires `DoubleEndedIterator`.
                  - `.copied()` — `&T` to `T` for `Copy` types. Never `.cloned()` on `Copy` types.
                  - `.cloned()` — `&T` to `T` for `Clone` types. Only when cloning is semantically correct.
                  - `.scan(state, f)` — stateful transformation threading state through calls.
                  - `.fold(init, f)` — reduce to a single value. Use `.sum()` or `.product()` for numeric aggregation.
                  - `.reduce(f)` — fold without initial value; returns `Option`.
                  - `.min_by_key(f)` / `.max_by_key(f)` — find extreme by key function.
                  - `.position(p)` / `.find(p)` — find index or value.
                  - `.any(p)` / `.all(p)` — short-circuit boolean tests. Never `.filter(p).count() > 0` instead of `.any(p)`.
                  - `.count()` — consume and count. Never `.collect::<Vec<_>>().len()`.
                  - `.partition(p)` — split into two `Vec`s.
                  - `.for_each(f)` — side-effecting consumption. Use `for` loop for multi-line bodies.
                  - `.collect::<Type>()` — materialize. Type annotation always present when not inferred.
                  - `.inspect(f)` — debug peek without transforming. Remove before committing.

                  ---

                  ### Collections Deep Reference

                  **Slice patterns:**
                  - Empty: `slice.is_empty()`. Never `slice.len() == 0`.
                  - Single element: `if let [element] = slice { ... }`.
                  - First: `slice.first()` → `Option<&T>`. Never `slice.get(0)`.
                  - Last: `slice.last()` → `Option<&T>`.
                  - Safe index: `slice.get(i)` → `Option<&T>`. `slice[i]` panics; only when index provably in bounds.
                  - Binary search: `slice.binary_search(&value)` on sorted slice. Returns `Result<usize, usize>`.
                  - Sort stable: `slice.sort()`. Sort unstable (faster): `slice.sort_unstable()`. By key: `sort_by_key(|x| x.field)`.
                  - Dedup: `slice.dedup()` on sorted slice. By key: `slice.dedup_by_key(|x| x.field)`.

                  **HashMap patterns:**
                  - `.entry(key).or_insert(value)` — insert if absent, return mutable ref. Never get-check-insert.
                  - `.entry(key).or_insert_with(|| expensive())` — lazy insert.
                  - `.entry(key).or_default()` — insert `Default::default()` if absent.
                  - `.entry(key).and_modify(|v| *v += 1).or_insert(0)` — modify if present, insert if absent.
                  - `.get(&key)` → `Option<&V>`. `.get_mut(&key)` → `Option<&mut V>`.
                  - `.remove(&key)` → `Option<V>`. `.remove_entry(&key)` → `Option<(K, V)>`.
                  - Iteration: `.iter()` → `(&K, &V)`. `.iter_mut()` → `(&K, &mut V)`. `.into_iter()` → `(K, V)`.
                  - Capacity: `HashMap::with_capacity(n)` upfront. `.reserve(n)` to grow. `.shrink_to_fit()` after bulk removal.

                  ---

                  ### Lifetime Deep Reference

                  **Lifetime elision rules:**
                  - Rule 1: each `&T` parameter gets its own lifetime.
                  - Rule 2: one input lifetime → all output lifetimes get it.
                  - Rule 3: `&self`/`&mut self` method → `self` lifetime given to all outputs.
                  - None of these apply: explicit lifetimes required.

                  **Common lifetime signatures:**
                  - `fn foo<'a>(x: &'a T) -> &'a U` — output tied to input.
                  - `fn foo<'a, 'b>(x: &'a T, y: &'b U) -> &'a V` — output tied to first input only.
                  - `struct Foo<'a> { reference: &'a T }` — `Foo` cannot outlive `T`.
                  - `'a: 'b` — `'a` outlives `'b`.
                  - `for<'a> F: Fn(&'a T) -> &'a U` — higher-ranked: works for any lifetime.

                  **Anti-patterns:**
                  - Unnecessary `'static` bound: only add when the value is stored in a spawned task or `Arc` genuinely requiring `'static`.
                  - Annotating lifetimes the compiler would infer: adds noise.
                  - Struct lifetime parameters with no corresponding `&'a` fields: either add the field or remove the parameter.
                  - Shadowing lifetime names across nested scopes.

                  ---

                  ### Async Deep Reference

                  **Function structure:**
                  - `async fn` with no `.await` point: remove `async`. Immediate `Ready` future with unnecessary overhead.
                  - CPU-bound work in `async fn`: move to `tokio::task::spawn_blocking`. CPU work starves the executor.
                  - Recursive `async fn`: requires `Box::pin(async { ... })` to break infinite type size.
                  - Single `async fn` wrapping one other `async fn` with no logic: remove the wrapper.

                  **Tokio runtime:**
                  - One `#[tokio::main]` per binary, at the entry point. Never nested runtimes.
                  - `#[tokio::main(flavor = "multi_thread")]` — default. `worker_threads` left to tokio's default (CPU count) unless profiling shows a different count is better.
                  - `#[tokio::main(flavor = "current_thread")]` only for single-threaded applications. Document why.
                  - `#[tokio::test]` for async test functions.

                  **Synchronization primitive selection:**
                  - `tokio::sync::Mutex<T>` — guards held across `.await`. Async code accessing `T`.
                  - `std::sync::Mutex<T>` — guards NOT held across `.await`. Brief synchronous access only.
                  - `tokio::sync::RwLock<T>` — many readers, rare writers.
                  - `tokio::sync::Semaphore` — limit concurrent access to N. Rate limiting, connection pooling.
                  - `tokio::sync::Notify` — wake-up signal between tasks.
                  - `tokio::sync::watch` — single producer, multi consumer, last value wins. Config updates.
                  - `tokio::sync::broadcast` — single producer, multi consumer, all receive all messages.
                  - `tokio::sync::mpsc` — multi producer, single consumer. Default task channel.
                  - `tokio::sync::oneshot` — single use, request/response between tasks.

                  **Cancellation safety:**
                  - `.await` points are cancellation points. Dropped futures are dropped at the last `.await`.
                  - Resources acquired before `.await` must be released in `Drop` (RAII).
                  - Cancellation-unsafe futures must never be used as unprotected branches in `tokio::select!`.
                  - Document cancellation safety: `/// # Cancellation Safety\n/// This function is cancellation-safe.` or explicitly not, with the reason.

                  **Backpressure:**
                  - All channels are bounded. `tokio::sync::mpsc::channel(CAPACITY)`. Document the capacity and its rationale.
                  - Never `unbounded_channel()` in production code. Unbounded channels are memory leaks under load.
                  - `buffer_unordered(N)` for concurrent stream processing with a concurrency limit.

                  ---

                  ### Concurrency Deep Reference

                  **Thread design:**
                  - Always name threads: `std::thread::Builder::new().name("worker".to_owned()).spawn(...)`. Thread names appear in panic messages.
                  - Always join thread handles. Never detach silently.
                  - `std::thread::scope` for threads that borrow from the enclosing scope. Avoids `Arc` when data is only needed during the thread's lifetime.

                  **Arc patterns:**
                  - `Arc::clone(&arc)` — explicit clone signals reference count increment, not data clone.
                  - `Arc<T>` for shared immutable data across threads.
                  - `Arc<Mutex<T>>` for shared mutable data across threads.
                  - `Arc<RwLock<T>>` for shared data: many readers, rare writers.
                  - `Weak<T>` to break `Arc` reference cycles. Parent holds `Arc`, children hold `Weak`.

                  **Lock protocol:**
                  - Lock ordering: documented and consistently enforced. `// Lock ordering: A then B. Never acquire B without holding A.`
                  - Locks held for minimum duration. Compute what you need, then lock and mutate, then release immediately.
                  - Never hold a lock while calling external code (callbacks, trait method implementations from outside the crate).
                  - `try_lock()` when lock unavailability is a recoverable condition.
                  - Write locks on `RwLock`: minimize hold time. Never blocking IO under a write lock.

                  **Atomics:**
                  - `Relaxed` for counters with no data synchronization requirement.
                  - `Acquire` on load + `Release` on store for producer/consumer synchronization.
                  - `AcqRel` on read-modify-write in synchronization primitives.
                  - `SeqCst` only when global sequential consistency across multiple atomics is required. Document why.
                  - `fetch_add`, `fetch_sub` for atomic increment/decrement. `load` + compute + `store` is NOT atomic.
                  - `compare_exchange` for optimistic concurrency control.

                  ---

                  ### Testing Deep Reference

                  **Test organization:**
                  - Unit tests: bottom of the file they test. `#[cfg(test)] mod tests { use super::*; }`.
                  - Integration tests: `tests/` directory. One file per feature or scenario. Note: use `tests/common/mod.rs`, never `tests/common.rs`.
                  - Benchmark tests: `benches/` directory.
                  - Shared test utilities: `tests/common/mod.rs`. Declared in each integration test file with `mod common;`.

                  **Test structure:**
                  - Arrange-Act-Assert pattern. Three phases separated by blank lines.
                  - Arrange: set up data and dependencies.
                  - Act: call the function under test. One call per test.
                  - Assert: verify results.
                  - One logical behavior tested per function. Multiple related asserts on the same result: acceptable. Testing unrelated behaviors in one test: not.

                  **What to test:**
                  - The public API. Not private implementation details.
                  - Every distinct code path that produces a different observable result.
                  - Every error condition documented in `# Errors`.
                  - Every boundary: empty collection, single element, maximum value, minimum value, zero.
                  - Integration tests: real dependencies (database, network).

                  **Test doubles:**
                  - No mocking frameworks. Define a test-specific struct implementing the same trait.
                  - Test doubles in `#[cfg(test)]` modules or `tests/common/`.
                  - Never add `#[cfg(test)]` code to production structs. Design for testability via trait injection.
                  - Prefer fakes (working implementations with inspectable state) over mocks (assertion-based).
                  - In-memory implementations: `InMemoryUserRepository`. Used in unit tests, not integration tests.

                  **Proptest:**
                  - Property: a statement true for all valid inputs. Examples: round-trip serialization, sort produces sorted output, valid input constructs successfully.
                  - Every newtype defines a proptest `Strategy` in its test module.
                  - `prop_assert!` and `prop_assert_eq!` inside `proptest!` — they return `TestCaseError` instead of panicking.
                  - Never suppress shrinking.

                  ---

                  ### Performance Deep Reference

                  **Profile before optimizing:**
                  - `cargo flamegraph` for CPU profiling. `heaptrack` for heap allocation. `cargo bench` for microbenchmarks.
                  - Profile in release mode. Debug builds have different characteristics.
                  - A comment that says "this is fast" without a benchmark number is not evidence.

                  **Allocation discipline:**
                  - `String::with_capacity(n)` before building strings in loops.
                  - `Vec::with_capacity(n)` before filling vectors when count is known.
                  - `Box<[T]>` instead of `Vec<T>` for collections created once and never resized. Saves 8 bytes.
                  - `Cow<'a, T>` when most values are borrowed but occasionally owned. Avoids allocation in the common case.
                  - Arena allocation (`bumpalo`) for many short-lived allocations in a bounded scope.
                  - `collect::<Vec<_>>()` materializes the entire iterator. Avoid when one pass suffices.

                  **Cache efficiency:**
                  - Struct-of-Arrays for bulk-processed homogeneous data: three `Vec<f64>` instead of `Vec<Particle>` with three `f64` fields. SIMD and prefetching work better.
                  - Array-of-Structs when operations on a single entity need all its fields.
                  - `Vec<T>` stores data contiguously. `Vec<Box<T>>` stores scattered pointers. Prefer `Vec<T>`.
                  - `SmallVec<[T; N]>` for collections usually small but occasionally large.

                  **Vectorization:**
                  - Iterator chains on slices auto-vectorize. Write clean scalar code first.
                  - Verify with `cargo asm` that the hot loop uses SIMD instructions in release builds.
                  - Keep branches out of inner loops. Compute branch conditions outside the loop.

                  ---

                  ### Dependency Management Deep Reference

                  **Choosing dependencies:**
                  - Before adding: could this be implemented correctly in under 100 lines? If yes, implement it.
                  - Permitted without apology: `serde`, `tokio`, `thiserror`, `anyhow`, `tracing`, `clap`, `uuid`, `chrono`, `reqwest`, `sqlx`, `axum`, `tower`, `bytes`, `http`, `criterion`, `proptest`.
                  - Evaluate: active maintenance, security track record, compile time impact, binary size impact.
                  - `cargo-audit` in CI. A published vulnerability is remediated within one release cycle.

                  **Version management:**
                  - Versions declared once in `[workspace.dependencies]`.
                  - `^` semver requirement (default) for libraries. Exact pinning (`=1.2.3`) only for known regressions or security-critical dependencies.
                  - `cargo update` regularly. Commit lock file changes as `chore: update dependencies`.
                  - `cargo build --timings` to identify slow-to-compile dependencies.

                  ---

                  ### Serde Deep Reference

                  **Derive vs. manual:**
                  - `#[derive(Serialize, Deserialize)]` always. Never manual `impl Serialize` or `impl Deserialize` when derive produces correct code.
                  - For validated deserialization: `#[serde(try_from = "RawType")]` pattern. Define `struct RawFoo` with derived `Deserialize`, implement `TryFrom<RawFoo> for Foo` with validation. `Foo` gets `#[serde(try_from = "RawFoo")]`.

                  **Field attributes reference:**
                  - `#[serde(rename = "jsonFieldName")]` — rename individual field.
                  - `#[serde(rename_all = "camelCase")]` — rename all fields systematically.
                  - `#[serde(default)]` — missing field uses `Default::default()`.
                  - `#[serde(default = "path::to::fn")]` — missing field uses the provided function.
                  - `#[serde(skip)]` — exclude field entirely. Must implement `Default`.
                  - `#[serde(skip_serializing_if = "Option::is_none")]` — omit `None` from output.
                  - `#[serde(skip_serializing_if = "Vec::is_empty")]` — omit empty collections.
                  - `#[serde(flatten)]` — inline struct fields into parent. Use sparingly.
                  - `#[serde(deny_unknown_fields)]` — reject unknown fields on input. Use on all input types.
                  - `#[serde(with = "module")]` — custom serialize/deserialize via module.
                  - `#[serde(alias = "old_name")]` — accept both old and new name during transition.

                  **Versioning serialized data:**
                  - New optional fields: `#[serde(default)]`. Old data deserializes with default.
                  - Renamed fields: `#[serde(alias = "old_name")]` accepts both names.
                  - Removed fields: `#[serde(skip_deserializing)]` before full removal.
                  - Structural changes: version field + `#[serde(tag = "version")] enum DataVersioned { V1(DataV1), V2(DataV2) }`.

                  ---

                  ### Documentation Deep Reference

                  **Writing quality doc comments:**
                  - Documentation is for the caller, not the implementer. Describe what from the caller's perspective.
                  - Never restate the type signature in prose: `fn get_user(id: UserId) -> Option<User>` does not need "Gets a user by UserId, returning Option<User>." Write what the caller needs: "Returns the user with the given ID, or `None` if no user exists with that ID."
                  - `# Examples` code must compile and pass as doc tests. Run `cargo test --doc`. Failing doc test examples are misinformation.
                  - Performance-sensitive functions: `# Complexity` section with time and space complexity.
                  - Non-obvious algorithmic choices: `# Algorithm` section.
                  - `# Invariants` on types: every property guaranteed for all instances constructed via the public API.

                  **Module documentation (`//!` in `mod.rs`):**
                  - First paragraph: what types and functionality this module provides.
                  - Second paragraph: why this module exists as a separate semantic boundary.
                  - Third paragraph (optional): usage example or link to the primary type.
                  - Do not list every type. Explain purpose and concept, not inventory.

                  **Crate-level documentation (`//!` in `lib.rs`):**
                  - First paragraph: one sentence describing what the crate does.
                  - Second paragraph: who uses it and for what.
                  - Third paragraph: minimal end-to-end example of the primary use case.
                  - `# Features` section listing all Cargo features.
                  - `# Compatibility` section: MSRV and platform requirements.

                  ---

                  ### Free-Standing Functions Are Forbidden

                  This is one of the most important structural rules. A free-standing function that operates on a type belongs inside an `impl` block. A free-standing function that produces output belongs behind a trait. There is almost no legitimate reason for a free-standing function to exist in production Rust code.

                  **The rule:**
                  - Every function that takes a value of type `T` as its primary argument is a method on `T`. Move it into `impl T`.
                  - Every function that formats, displays, or renders a value implements `Display` or `Debug` on that value. It is not a free function.
                  - Every function that converts from type `A` to type `B` is `impl From<A> for B` or `impl TryFrom<A> for B`. It is not `fn convert_a_to_b(a: A) -> B`.
                  - Every function that checks a condition on a value is a method: `fn is_valid(&self) -> bool`, not `fn is_valid_user(user: &User) -> bool`.
                  - Every function that constructs a value is `T::new()` or `T::try_new()`. Not `fn create_user(name: Name, email: Email) -> User`.
                  - Every function that serializes, hashes, or summarizes a value implements the appropriate trait: `Serialize`, `Hash`, `Display`. Not `fn serialize_user(user: &User) -> String`.

                  **The red flag examples — every one of these is wrong:**
                  - `fn render_user(user: &User) -> String` — implement `Display for User`.
                  - `fn format_error(error: &Error) -> String` — implement `Display for Error`.
                  - `fn validate_email(email: &str) -> bool` — implement `fn is_valid(&self) -> bool` on `EmailAddress`.
                  - `fn user_to_json(user: &User) -> String` — derive `Serialize`, call `serde_json::to_string`.
                  - `fn make_connection(config: &Config) -> Connection` — implement `Connection::new(config: &Config)` or `impl TryFrom<&Config> for Connection`.
                  - `fn compare_users(a: &User, b: &User) -> bool` — implement `PartialEq for User`.
                  - `fn hash_user(user: &User) -> u64` — implement `Hash for User`.
                  - `fn default_config() -> Config` — implement `Default for Config`.
                  - `fn parse_user_id(s: &str) -> Result<UserId, ParseError>` — implement `FromStr for UserId`.
                  - `fn clone_session(session: &Session) -> Session` — implement `Clone for Session`.
                  - `fn empty_queue() -> Queue` — implement `Default for Queue`.
                  - `fn sort_users(users: &mut Vec<User>)` — implement `Ord for User`, call `users.sort()`.

                  **Legitimate free-standing functions — exhaustive list:**
                  - `main()` — the binary entry point.
                  - Functions in `mod tests` that are test helpers with no natural type owner.
                  - Top-level algorithm functions that operate equally on multiple unrelated types and cannot be expressed as a trait method without introducing an artificial trait.
                  - Functions exposed as `pub` in a crate API specifically because the caller cannot call a method (e.g., a callback registered with a C library that requires a function pointer).

                  **If you are about to write a free-standing function, ask these questions in order:**
                  1. Does this function take a value of a type I own as its primary argument? → Make it a method.
                  2. Does this function produce a string representation? → Implement `Display` or `Debug`.
                  3. Does this function convert between two types? → Implement `From` or `TryFrom`.
                  4. Does this function construct a value? → Make it `new()` or `try_new()`.
                  5. Does this function check a property? → Make it a predicate method (`is_*`, `has_*`, `can_*`).
                  6. Does this function compare two values? → Implement `PartialEq`, `Eq`, `PartialOrd`, `Ord`.
                  7. Does this function aggregate or summarize? → Implement `Iterator`, `FromIterator`, or `Display`.
                  If none of the above apply, the function may be free-standing. Otherwise it must not be.

                  ---

                  ### Trait Implementation Is Not Optional

                  LLMs consistently fail to implement applicable standard library traits, leaving callers to write boilerplate conversion code, explicit comparisons, and manual string formatting. This is laziness encoded into the API. Every applicable trait must be implemented. There is no excuse for omitting them.

                  **The complete mandatory trait checklist — evaluate every type against every trait:**

                  `Debug` — every type, every time. No exceptions. A type without `Debug` cannot be logged, cannot be inspected in a test failure, cannot be used in `assert_eq!`. There is no situation where `Debug` should not be derived. If you cannot derive it (raw pointers, FFI types), implement it manually.

                  `Display` — every type that has a meaningful string representation for a human reader. This includes: error types, domain value types (email addresses, user IDs, amounts, URLs), status enums, result types shown in a UI or log. If the type ever appears in a formatted string, in a log message, in a user-facing error, or in a CLI output, it implements `Display`. Forgetting `Display` and calling `format!("{:?}", value)` is always wrong.

                  `Clone` — every type that can logically be duplicated. If a function needs two copies of a value, the type implements `Clone`. If you find yourself writing `let copy = MyType { field_a: original.field_a, field_b: original.field_b }` instead of `original.clone()`, the type is missing `Clone`.

                  `Copy` — every type that is small (fits in a few registers), contains no heap resources, and has value semantics. `UserId { value: u64 }` is `Copy`. `Milliseconds { value: u64 }` is `Copy`. `Point { x: f64, y: f64 }` is `Copy`. `StatusCode { value: u16 }` is `Copy`. If the type can be `Copy`, it must be `Copy`. Forcing callers to `.clone()` a `Copy`-eligible type is an API defect.

                  `PartialEq` — every type where equality comparison has meaning. Almost every type. If two instances of the type can be meaningfully compared, derive `PartialEq`. If you find yourself writing `a.id() == b.id()` instead of `a == b`, the type is missing `PartialEq`.

                  `Eq` — always derived alongside `PartialEq` when the equality is total (reflexive, symmetric, transitive). Almost all types satisfy this. The exceptions are floating-point types (`f32`, `f64`) and types containing them, where `NaN != NaN`. For all other types: if you derive `PartialEq`, derive `Eq`.

                  `PartialOrd` and `Ord` — every type with a meaningful ordering. `Timestamp`, `Version`, `Priority`, `Amount`, `Rank`, `Score`, `Index`, `Count` — all of these have natural orderings. If callers would ever want to sort a collection of this type, or compare two instances with `<`, `>`, `<=`, `>=`, or pass them to `min()`/`max()`, the type implements `Ord`. If you find yourself writing `a.value() < b.value()` to compare two newtypes, the type is missing `Ord`.

                  `Hash` — every type used as a `HashMap` key or `HashSet` element. Every type that implements `Eq` should also implement `Hash` so it can be used in hash-based collections. The invariant: `a == b` implies `hash(a) == hash(b)`. Derive both together.

                  `Default` — every type with a meaningful zero, empty, or initial state. `Config::default()` should produce a valid configuration with sensible defaults. `Queue::default()` should produce an empty queue. `Counters::default()` should produce all-zero counters. If there is a natural "starting state," implement `Default`. If there is not, do not implement it — a misleading `Default` is worse than none.

                  `From<T>` — for every lossless, infallible conversion from another type to this type. If a `UserId` wraps a `u64`, implement `From<u64> for UserId`. If a `Name` wraps a `String`, implement `From<String> for Name` and `From<&str> for Name`. If a domain type can be created from a primitive, implement `From`. Never write a free-standing conversion function when `From` would express it.

                  `TryFrom<T>` — for every fallible conversion from another type to this type. `EmailAddress` cannot be created from an arbitrary `&str` without validation — implement `TryFrom<&str> for EmailAddress`. `Port` cannot hold values above 65535 — implement `TryFrom<u32> for Port`. If creation can fail for any reason, the entry point is `TryFrom`, not a free-standing `validate_and_create` function.

                  `FromStr` — every type that can be parsed from a string. `UserId`, `EmailAddress`, `IpAddress`, `Url`, `Version`, `Duration`, `Color` — all implement `FromStr`. Users call `.parse::<Type>()`. This is the Rust convention. A free-standing `parse_foo(s: &str) -> Result<Foo, Error>` is wrong when `FromStr` is the correct expression.

                  `AsRef<T>` — when a type transparently borrows as another type. String newtypes implement `AsRef<str>`. Path newtypes implement `AsRef<Path>`. Byte buffer newtypes implement `AsRef<[u8]>`. This allows passing the newtype to any function accepting `impl AsRef<str>` or `impl AsRef<Path>`.

                  `Borrow<T>` — alongside `AsRef<T>` for types used as `HashMap` keys, so that lookups can use the borrowed form. `HashMap<EmailAddress, User>` should be queryable with `&str`. Implement `Borrow<str> for EmailAddress`.

                  `IntoIterator` — every collection type. `impl IntoIterator for &MyCollection`, `impl IntoIterator for &mut MyCollection`, `impl IntoIterator for MyCollection`. This allows the collection to be used in `for` loops and iterator chains directly.

                  `Iterator` — every type that produces a sequence. If you have a type that yields elements one at a time, implement `Iterator`. Do not wrap it in a closure or return a `Vec`.

                  `Extend<T>` — every collection type. `impl Extend<T> for MyCollection` allows bulk insertion from an iterator. Enables `.extend(iter)` at call sites.

                  `FromIterator<T>` — every collection type. `impl FromIterator<T> for MyCollection` allows `.collect::<MyCollection>()`. If your type is a collection, it must be collectable.

                  `Error` — every error type, via `thiserror`. Error types that do not implement `std::error::Error` cannot be used with `?`, cannot be boxed as `Box<dyn Error>`, and are first-class citizens of no error handling framework.

                  `Serialize` and `Deserialize` — every type that crosses a serialization boundary. This includes: request/response types, database row types, config types, event types, message types. If the type leaves or enters the Rust process boundary, it derives both.

                  `Send` and `Sync` — automatically derived when all fields are `Send`/`Sync`. Verify with `static_assertions::assert_impl_all!(MyType: Send, Sync)` in the test module of types that must be thread-safe.

                  **Trait implementation is the API.** A type without `Display` forces callers to write formatting code. A type without `From` forces callers to write conversion code. A type without `Ord` forces callers to write comparison code. Every missing trait is work pushed onto every caller, repeated across the entire codebase. Implement the trait once. Never force callers to reimplement it.

                  ---

                  ### Comment Policy — Almost No Comments

                  Comments are a last resort. The code is the documentation. A well-named variable, a well-named function, a well-chosen type, and a well-structured `impl` block communicate more than any comment ever could. A comment that explains what the code does is a confession that the code's names are wrong.

                  **The rule: no inline comments. No block comments. No explanatory comments.**

                  The only accepted comments:

                  1. Module-level `//!` documentation at the top of `mod.rs` files. This is the single place where prose explanation is required. One paragraph maximum. No bullet lists.

                  2. `// SAFETY:` before every `unsafe` block. This is mandatory and non-negotiable. It is not an explanation of what the code does — it is a proof that the unsafe contract is upheld.

                  3. `// UNREACHABLE:` before `unreachable!()` calls, explaining why the branch cannot be reached given the type system invariants.

                  4. `// TODO: #<issue-number>` when a known limitation must be acknowledged in the code itself. No other `TODO` form is accepted. No `TODO` without an issue number.

                  **Everything else is forbidden:**

                  - `// Get the user from the database` before a database call — the function name and return type already say this.
                  - `// Check if the email is valid` before `email.is_valid()` — the method name says this.
                  - `// Convert the raw bytes to a string` before a `from_utf8` call — the function name says this.
                  - `// Return early if there is an error` before an `?` — everyone knows what `?` does.
                  - `// Create a new vector` before `Vec::new()` — it is literally `Vec::new()`.
                  - `// Loop over all users` before `for user in users` — this is insulting to the reader.
                  - Section dividers: `// ===== Helpers =====`, `// --- Private ---`, `// Constructors` — these are symptoms of a file that needs to be split into modules, not annotated.
                  - `// This is safe because...` without using the `// SAFETY:` convention — use the convention.
                  - `// Note:` comments explaining surprising behavior — fix the surprising behavior or rename the construct so it is not surprising.
                  - `// We use X instead of Y because...` — if X is correct, its name communicates why. If a comment is needed to justify the choice, the choice is probably wrong.
                  - Doc comments (`///`) on private items. Private items are implementation details. They do not have doc comments.
                  - `///` doc comments that restate the function signature in prose. `/// Returns the user ID.` on `fn user_id(&self) -> UserId` adds nothing. Delete it.

                  **When you feel the urge to write a comment, do this instead:**

                  - Extract the commented block into a named function whose name is the comment.
                  - Rename the variable or function so the comment is unnecessary.
                  - Introduce a type that makes the constraint self-evident.
                  - Use a let binding with a descriptive name instead of a comment explaining an expression.

                  `let is_within_rate_limit = request_count < MAX_REQUESTS_PER_WINDOW;` needs no comment.
                  `let requires_admin_approval = amount > APPROVAL_THRESHOLD && !requester.has_admin_role();` needs no comment.
                  `let effective_timeout = requested_timeout.min(MAX_ALLOWED_TIMEOUT);` needs no comment.

                  If the code cannot be made self-evident through naming and structure, that is a design problem. Fix the design.

                  ---

                  ### Assignment-Heavy Style

                  Complex expressions are always decomposed into named intermediate variables. A chain of three nested function calls is three lines with three named bindings. The name of each binding describes what the value represents. The reader can understand each step in isolation.

                  **The rule: one operation per line, every intermediate value is named.**

                  Wrong:
                  ```
                  send_notification(build_message(fetch_template(config.template_id())?, user.display_name()), channel)?;
                  ```

                  Right:
                  ```
                  let template_id = config.template_id();
                  let template = fetch_template(template_id)?;
                  let recipient_name = user.display_name();
                  let message = build_message(template, recipient_name);
                  send_notification(message, channel)?;
                  ```

                  The named version is longer. It is also unambiguous, debuggable, and readable. Every binding can be inspected in a debugger. Every step can be tested individually. Every name communicates intent.

                  **Rules for intermediate bindings:**

                  - Any expression that involves more than one operation has a name.
                  - The name describes what the value is, not how it was computed. `let validated_email = email.validate()?` not `let result = email.validate()?`.
                  - Boolean conditions that involve more than one comparison are extracted: `let has_expired = expiry < Instant::now();` not `if session.expiry() < Instant::now() && !session.is_revoked()`.
                  - Long method chains (more than two chained calls) are broken into steps with named bindings.
                  - Closures passed as arguments: if the closure is more than one line, extract it to a named variable first. `let transform = |item: &Item| { ... }; items.iter().map(transform)`.
                  - Conditional expressions: avoid `let x = if condition { a } else { b }` when `a` and `b` are themselves complex expressions. Extract each branch.
                  - `match` expressions as arguments to a function: extract the `match` to a named binding first.
                  - Struct construction: every argument to a struct constructor is a named binding. Never `User::new(request.name().to_owned(), Email::try_from(request.email())?, UserId::from(db.next_id()))`. Each argument is its own line and its own name.

                  **Nesting depth:**
                  - Maximum nesting depth in a function body: 3 levels. More than 3 levels signals a missing extraction.
                  - Each level of nesting is: a function body (level 1), a block or control flow (level 2), an inner block (level 3). A fourth level means extract a function.
                  - Early return pattern (`guard clauses`) flattens nesting: check preconditions at the top of the function body, return early if they fail. The happy path is at the lowest nesting level.

                  **Guard clauses:**
                  Wrong:
                  ```
                  fn process(input: &Input) -> Result<Output, Error> {
                      if input.is_valid() {
                          if let Some(data) = input.data() {
                              // 30 lines of logic
                          } else {
                              Err(Error::MissingData)
                          }
                      } else {
                          Err(Error::InvalidInput)
                      }
                  }
                  ```

                  Right:
                  ```
                  fn process(input: &Input) -> Result<Output, Error> {
                      let valid_input = input.validate()?;
                      let data = valid_input.data().ok_or(Error::MissingData)?;
                      // logic at flat level
                  }
                  ```

                  ---

                  ### Struct Parameters — No Naked Multi-Argument Functions

                  A function that takes more than one argument where those arguments represent configuration, options, or a logical group belongs to a struct. The rule is simple and has no exceptions.

                  **The rule:**
                  - Functions with exactly one primary subject argument (`&self`, `&mut self`, or `T`) and zero additional arguments: acceptable.
                  - Functions with one subject and one additional argument where the additional argument is atomic and has no relationship to other arguments: acceptable. `fn find_by_id(&self, id: UserId) -> Option<&User>` is fine.
                  - Functions with two or more non-`self` arguments: the arguments are collected into a named struct. The struct is the parameter.

                  **Wrong:**
                  ```
                  fn create_user(name: Name, email: EmailAddress, role: Role, department: Department) -> Result<User, Error>
                  fn send_email(to: EmailAddress, subject: Subject, body: Body, reply_to: Option<EmailAddress>) -> Result<(), Error>
                  fn search(query: &str, limit: usize, offset: usize, sort: SortOrder, filters: Vec<Filter>) -> Results
                  fn connect(host: &str, port: Port, timeout: Duration, tls: TlsConfig) -> Result<Connection, Error>
                  ```

                  **Right:**
                  ```
                  fn create(params: CreateUserParams) -> Result<User, Error>
                  fn send(email: Email) -> Result<(), Error>
                  fn search(query: SearchQuery) -> SearchResults
                  fn connect(options: ConnectionOptions) -> Result<Connection, Error>
                  ```

                  **The struct that carries the parameters:**
                  - Named after what it represents, not after the function: `CreateUserParams`, `ConnectionOptions`, `SearchQuery`, `EmailMessage`. Never `CreateUserArgs`, `ConnectArgs`, `SearchArgs`.
                  - Implements `Default` when any fields have sensible defaults.
                  - Implements `Debug`, `Clone`.
                  - Implements a builder (`CreateUserParamsBuilder`) when fields are optional or require validation.
                  - Lives in the same module as the function it parameterizes.
                  - All fields are `pub` only when the struct has no invariants. If the struct has required fields or validation, fields are private and construction is via `new()` or a builder.

                  **Constructors are not exempt:**
                  - `fn new(name: Name, email: EmailAddress, role: Role) -> Self` with three parameters: introduce `NewUserParams { name, email, role }` and call `fn new(params: NewUserParams) -> Self`.
                  - `fn try_new(host: String, port: u16, timeout_seconds: u64) -> Result<Self, Error>`: introduce `ConnectionConfig { host, port, timeout_seconds }` and call `fn try_new(config: ConnectionConfig) -> Result<Self, Error>`.

                  **The benefits are not optional:**
                  - The call site is self-documenting: `User::new(CreateUserParams { name, email, role })` not `User::new(name, email, role)` where argument order is invisible.
                  - Adding a new parameter to a function is a breaking change. Adding a new field with a default to the params struct is not.
                  - The params struct can be constructed partially and passed around before the function is called.
                  - The params struct implements `Default`, so callers can use struct update syntax to override only what they need.

                  ---

                  ### Structures Everywhere — Design Principle

                  Types communicate intent. Raw primitives and generic containers communicate nothing. Every concept in the domain, every configuration value, every intermediate computation result that has a name and a meaning is a type.

                  **Use a struct when:**
                  - Two or more values always travel together and have a collective identity.
                  - A value has a name and a unit that cannot be inferred from the primitive type alone.
                  - A computation produces an intermediate result that will be passed to another function.
                  - A function returns multiple related values.
                  - A type alias would be used — use a newtype struct instead.

                  **Use an enum when:**
                  - A value can be exactly one of N known alternatives.
                  - A function can succeed in multiple distinct ways (not just `Ok(T)` but `Ok(Created)`, `Ok(Updated)`, `Ok(NoChange)`).
                  - A state machine has distinct states with different associated data.
                  - A configuration option has a fixed set of choices.
                  - A `bool` parameter would be passed — it is always an enum.
                  - An `Option<bool>` would be used — it is always a three-variant enum.
                  - An integer is used as a discriminant — it is always an enum.

                  **Specific structural replacements:**
                  - `(f64, f64)` → `struct Point { x: f64, y: f64 }` or `struct LatLng { latitude: f64, longitude: f64 }`.
                  - `(String, u16)` for a host/port pair → `struct SocketAddress { host: String, port: Port }`.
                  - `(Vec<User>, usize)` for paginated results → `struct Page<T> { items: Vec<T>, total_count: usize }`.
                  - `Option<String>` for an optional message → `enum Outcome { Success, SuccessWithNote { note: String }, Failure { reason: String } }` or a dedicated type.
                  - `bool` return value from a mutation function → `enum MutationResult { Applied, Skipped }`.
                  - `Vec<(String, String)>` for headers → `struct Headers { entries: Vec<Header> }` where `struct Header { name: HeaderName, value: HeaderValue }`.
                  - `HashMap<String, String>` for metadata → `struct Metadata { fields: HashMap<MetadataKey, MetadataValue> }`.
                  - `String` for a status → `enum Status { Active, Inactive, Suspended, Pending }`.
                  - `u32` for an error code → `enum ErrorCode { NotFound, Unauthorized, RateLimited, InternalError }`.
                  - `Vec<Box<dyn Any>>` for heterogeneous data → a proper enum with variants.

                  **Return type design:**
                  - Functions never return `(T, U)`. They return a named struct.
                  - Functions never return `bool` when the two cases have different semantic meanings that the caller will branch on. Return an enum.
                  - Functions that can succeed in multiple distinguishable ways return an enum: `enum InsertResult { Inserted(Record), AlreadyExisted(Record) }` not `bool`.
                  - Functions that return a count and a collection return a struct: `struct QueryResult { rows: Vec<Row>, total: usize }` not `(Vec<Row>, usize)`.
                  - Functions in a builder chain return `Self`. Functions that produce a different type return that type. Never return `()` when the produced value might be useful.

                  ---

                  ### Clippy Configuration — Maximum Strictness

                  The clippy configuration in `clippy.toml` (or `.clippy.toml`) at the workspace root enables the maximum set of correct lints. This is the required configuration. Every lint listed here is enabled. Lints disabled per-file require a comment explaining the specific reason.

                  **`clippy.toml` required settings:**
                  ```
                  msrv = "1.70.0"
                  cognitive-complexity-threshold = 5
                  too-many-arguments-threshold = 2
                  too-many-lines-threshold = 40
                  trivial-copy-size-limit = 128
                  type-complexity-threshold = 250
                  ```

                  **Required lints in `Cargo.toml` or via `RUSTFLAGS`:**
                  ```
                  [lints.clippy]
                  # Pedantic group — enabled as errors
                  pedantic = "warn"
                  # Restriction group — selectively enabled
                  alloc_instead_of_core = "warn"
                  allow_attributes = "warn"
                  allow_attributes_without_reason = "warn"
                  arithmetic_side_effects = "warn"
                  as_conversions = "warn"
                  as_underscore = "warn"
                  assertions_on_result_states = "warn"
                  clone_on_ref_ptr = "warn"
                  create_dir = "warn"
                  dbg_macro = "warn"
                  decimal_literal_representation = "warn"
                  default_numeric_fallback = "warn"
                  deref_by_slicing = "warn"
                  disallowed_script_idents = "warn"
                  else_if_without_else = "warn"
                  empty_drop = "warn"
                  empty_structs_with_brackets = "warn"
                  error_impl_error = "warn"
                  exhaustive_enums = "warn"
                  exhaustive_structs = "warn"
                  exit = "warn"
                  expect_used = "warn"
                  filetype_is_file = "warn"
                  float_arithmetic = "warn"
                  float_cmp_const = "warn"
                  fn_to_numeric_cast_any = "warn"
                  format_push_string = "warn"
                  get_unwrap = "warn"
                  if_then_some_else_none = "warn"
                  impl_trait_in_params = "warn"
                  indexing_slicing = "warn"
                  inline_asm_x86_att_syntax = "warn"
                  integer_division = "warn"
                  large_include_file = "warn"
                  let_underscore_must_use = "warn"
                  let_underscore_untyped = "warn"
                  lossy_float_literal = "warn"
                  map_err_ignore = "warn"
                  mem_forget = "warn"
                  missing_assert_message = "warn"
                  missing_asserts_for_indexing = "warn"
                  missing_docs_in_private_items = "deny"
                  missing_inline_in_public_items = "warn"
                  mixed_read_write_in_expression = "warn"
                  mod_module_files = "warn"
                  multiple_inherent_impl = "warn"
                  multiple_unsafe_ops_per_block = "warn"
                  mutex_atomic = "warn"
                  needless_raw_strings = "warn"
                  non_ascii_literal = "warn"
                  panic = "warn"
                  panic_in_result_fn = "warn"
                  partial_pub_fields = "warn"
                  print_stderr = "warn"
                  print_stdout = "warn"
                  pub_without_shorthand = "warn"
                  rc_buffer = "warn"
                  rc_mutex = "warn"
                  redundant_type_annotations = "warn"
                  ref_patterns = "warn"
                  rest_pat_in_fully_bound_structs = "warn"
                  same_name_method = "warn"
                  self_named_module_files = "deny"
                  semicolon_inside_block = "warn"
                  semicolon_outside_block = "warn"
                  shadow_reuse = "warn"
                  shadow_same = "warn"
                  shadow_unrelated = "warn"
                  std_instead_of_alloc = "warn"
                  str_to_string = "warn"
                  string_add = "warn"
                  string_lit_chars_any = "warn"
                  string_slice = "warn"
                  string_to_string = "warn"
                  suspicious_xor_used_as_pow = "warn"
                  tests_outside_test_module = "warn"
                  todo = "warn"
                  try_err = "warn"
                  undocumented_unsafe_blocks = "deny"
                  unimplemented = "warn"
                  unnecessary_self_imports = "warn"
                  unneeded_field_pattern = "warn"
                  unreachable = "warn"
                  unseparated_literal_suffix = "warn"
                  unwrap_in_result = "warn"
                  unwrap_used = "warn"
                  use_debug = "warn"
                  verbose_file_reads = "warn"
                  wildcard_enum_match_arm = "warn"
                  ```

                  **Required `rustc` lints via `[lints.rust]` in `Cargo.toml`:**
                  ```
                  [lints.rust]
                  absolute_paths_not_starting_with_crate = "warn"
                  dead_code = "warn"
                  deprecated_in_future = "warn"
                  elided_lifetimes_in_paths = "warn"
                  explicit_outlives_requirements = "warn"
                  ffi_unwind_calls = "warn"
                  keyword_idents = "warn"
                  let_underscore_drop = "warn"
                  macro_use_extern_crate = "warn"
                  meta_variable_misuse = "warn"
                  missing_abi = "warn"
                  missing_copy_implementations = "warn"
                  missing_debug_implementations = "warn"
                  non_exhaustive_omitted_patterns = "warn"
                  rust_2018_idioms = "warn"
                  rust_2021_incompatible_closure_captures = "warn"
                  trivial_casts = "warn"
                  trivial_numeric_casts = "warn"
                  unit_bindings = "warn"
                  unnameable_types = "warn"
                  unreachable_pub = "warn"
                  unsafe_op_in_unsafe_fn = "deny"
                  unused_crate_dependencies = "warn"
                  unused_extern_crates = "warn"
                  unused_import_braces = "warn"
                  unused_lifetimes = "warn"
                  unused_macro_rules = "warn"
                  unused_qualifications = "warn"
                  unused_results = "warn"
                  variant_size_differences = "warn"
                  ```

                  **What these lints enforce — key ones explained:**
                  - `arithmetic_side_effects` — forbids `+`, `-`, `*` operators that can overflow. Forces `checked_*`, `saturating_*`, or `wrapping_*`.
                  - `as_conversions` — forbids all `as` casts. Use `From`/`Into`/`TryFrom`/`TryInto`.
                  - `expect_used` — forbids `.expect()` in non-test code. Forces proper error handling.
                  - `unwrap_used` — forbids `.unwrap()` in non-test code. Forces proper error handling.
                  - `indexing_slicing` — forbids `collection[index]` without bounds proof. Forces `.get(index)`.
                  - `integer_division` — forbids `/` on integers when truncation might be unintentional.
                  - `panic` — forbids `panic!()` calls in library code.
                  - `print_stdout` / `print_stderr` — forbids `println!` and `eprintln!`. Forces `tracing::`.
                  - `self_named_module_files = "deny"` — enforces `mod.rs` form. Forbids `module_name.rs` flat form.
                  - `mod_module_files = "warn"` — used together with `self_named_module_files` to ensure the `mod.rs` convention.
                  - `exhaustive_enums` — forces `#[non_exhaustive]` on public enums or explicit documentation that the enum is intentionally exhaustive and closed.
                  - `missing_docs_in_private_items = "deny"` — every item has a doc comment. (May be relaxed to `warn` in projects where private docs are aspirational rather than mandatory.)
                  - `undocumented_unsafe_blocks = "deny"` — every `unsafe` block requires a `// SAFETY:` comment. This is non-negotiable.
                  - `shadow_reuse`, `shadow_same`, `shadow_unrelated` — all three shadowing lints enabled. Variable shadowing is forbidden in all forms.
                  - `wildcard_enum_match_arm` — forbids `_ =>` in `match` on enums. Every variant must be named explicitly.
                  - `multiple_inherent_impl` — one `impl` block per type per file. Multiple `impl` blocks for the same type in the same file are forbidden.
                  - `partial_pub_fields` — all fields of a struct are either all `pub` or all private. Never a mix.
                  - `tests_outside_test_module` — test functions must be inside `#[cfg(test)] mod tests`.
                  - `dbg_macro` — `dbg!()` is forbidden in committed code.
                  - `todo` — `todo!()` is forbidden in committed code.
                  - `unimplemented` — `unimplemented!()` is forbidden in committed code.
                  - `unreachable` — `unreachable!()` requires justification (addressed by the `// UNREACHABLE:` comment rule).
                  - `str_to_string`, `string_to_string` — explicit about string allocations.
                  - `clone_on_ref_ptr` — `.clone()` on `Arc`/`Rc` must use `Arc::clone(&arc)` not `arc.clone()`.
                  - `use_debug` — forbids `{:?}` in non-test `format!`/`println!` calls. Use `Display` instead.
                  - `missing_copy_implementations` — if a type could be `Copy`, it must be `Copy`.
                  - `missing_debug_implementations` — if a type doesn't derive `Debug`, it's a build warning.
                  - `variant_size_differences` — warns when enum variants differ greatly in size; suggests `Box`ing the large variant.

                  **Per-lint disable policy:**
                  - Every `#[allow(clippy::some_lint)]` requires `#[allow(clippy::some_lint, reason = "specific reason this lint is incorrect here")]`.
                  - The `reason` field is mandatory (enforced by `allow_attributes_without_reason = "warn"`).
                  - `#[allow]` on a module or file is forbidden. Only on specific items.
                  - A codebase with more than 5 `#[allow]` attributes signals that the code needs to be fixed, not the lints.

                  ---

                  ### Impl Block Organization — One Structure, One Place

                  Every `impl` block for a type lives in the same file as the type definition. The type and all of its behavior are colocated. A reader who opens `src/user/mod.rs` sees the `User` struct, every method, every trait implementation, every associated function.

                  **`impl` block ordering within a file:**
                  1. The type definition (`struct`, `enum`).
                  2. The primary `impl TypeName` block: constructors first (`new`, `try_new`, named constructors), then predicate methods (`is_*`, `has_*`, `can_*`), then reader methods (take `&self`, return data), then mutation methods (take `&mut self`), then consuming methods (take `self`), then associated functions (no `self`).
                  3. `impl Default for TypeName` — if separate from the primary `impl`.
                  4. `impl Display for TypeName`.
                  5. `impl Debug for TypeName` — only if manual implementation is required; prefer `#[derive(Debug)]`.
                  6. `impl From<OtherType> for TypeName` — one `impl` per source type.
                  7. `impl TryFrom<OtherType> for TypeName` — one `impl` per source type.
                  8. `impl FromStr for TypeName`.
                  9. `impl PartialEq for TypeName` — only if manual; prefer `#[derive]`.
                  10. `impl Eq for TypeName` — only if manual.
                  11. `impl PartialOrd for TypeName` — only if manual.
                  12. `impl Ord for TypeName` — only if manual.
                  13. `impl Hash for TypeName` — only if manual.
                  14. `impl AsRef<T> for TypeName`.
                  15. `impl Borrow<T> for TypeName`.
                  16. `impl Deref for TypeName` — only for smart pointer types.
                  17. `impl Iterator for TypeName`.
                  18. `impl IntoIterator for TypeName` / `impl IntoIterator for &TypeName` / `impl IntoIterator for &mut TypeName`.
                  19. `impl Serialize for TypeName` — only if manual; prefer `#[derive]`.
                  20. `impl Deserialize for TypeName` — only if manual.
                  21. Custom trait implementations, alphabetical by trait name.
                  22. `#[cfg(test)] mod tests { ... }` — always last.

                  **Multiple `impl` blocks for the same type in the same file are forbidden** (enforced by `clippy::multiple_inherent_impl`). One `impl TypeName` block, one place. Trait impls are separate blocks but they are all in the same file.

                  **`impl` blocks in different files for the same type are forbidden.** A type's entire implementation lives in one file. If the impl is growing too large, the type is doing too much — split the type, not the impl.

                  ---

                  ### Architecture Patterns — Mandatory Structures

                  **Repository pattern:**
                  - Every domain entity that is persisted has a repository trait: `trait UserRepository`, `trait OrderRepository`.
                  - The trait lives in the same module as the entity: `src/user/mod.rs` contains `trait UserRepository`.
                  - The trait methods are in terms of domain types only. No SQL, no JSON, no HTTP in the trait signature.
                  - The concrete implementation lives in `src/user/repository.rs` under `src/user/` (i.e., `src/user/repository/mod.rs`).
                  - The concrete implementation is never referenced in business logic. Only the trait is referenced.
                  - `impl UserRepository for PostgresUserRepository` in the infrastructure layer.
                  - Tests use `InMemoryUserRepository` implementing the same trait.

                  **Service pattern:**
                  - Business logic that coordinates multiple domain types belongs in a service struct: `struct UserService<Repo: UserRepository>`.
                  - Services are generic over their dependencies via trait bounds.
                  - Services have a `new(repository: Repo) -> Self` constructor.
                  - Services do not contain state beyond their dependencies. All state lives in the domain types or the repository.
                  - Services implement the domain operations as methods: `fn register_user(&self, params: RegisterUserParams) -> Result<User, RegistrationError>`.
                  - Services are tested with in-memory implementations of their repository traits.

                  **Command and query separation:**
                  - Functions that change state (commands) return `Result<(), Error>` or `Result<DomainEvent, Error>`.
                  - Functions that read state (queries) return `Result<T, Error>` where `T` is the data.
                  - Commands and queries are never mixed in a single function.
                  - Command parameters are named structs: `struct RegisterUserCommand { name: Name, email: EmailAddress }`.
                  - Query parameters are named structs: `struct FindUserQuery { email: EmailAddress }`.

                  **Event-driven design:**
                  - Domain events are enums: `enum UserEvent { Registered(UserRegistered), EmailVerified(EmailVerified), Suspended(UserSuspended) }`.
                  - Each event variant's data is a named struct: `struct UserRegistered { user_id: UserId, email: EmailAddress, registered_at: Timestamp }`.
                  - Events are past-tense: `UserRegistered`, `OrderPlaced`, `PaymentFailed`.
                  - Event handlers are structs implementing a handler trait: `trait EventHandler<Event> { fn handle(&self, event: &Event) -> Result<(), HandlerError>; }`.

                  **Error hierarchy:**
                  - Application-level errors are enums with domain-specific variants.
                  - Infrastructure-level errors (database, network, serialization) are wrapped by domain errors.
                  - The domain layer never leaks infrastructure error types. `UserError::NotFound` not `sqlx::Error::RowNotFound`.
                  - Error conversion: `impl From<sqlx::Error> for UserError` in the infrastructure layer only.

                  **Configuration hierarchy:**
                  - One root config struct: `struct AppConfig`. All subsystem configs are fields: `database: DatabaseConfig`, `server: ServerConfig`, `auth: AuthConfig`.
                  - Each subsystem config struct implements `Default` with sensible defaults.
                  - Config is loaded once at startup: `AppConfig::from_env() -> Result<Self, ConfigError>`.
                  - Config is passed by reference through the application. It is never accessed via a global or a thread-local.
                  - Config fields are validated at load time. The application does not start with invalid config.

                  **Layered architecture — dependency direction:**
                  - Domain layer: pure business logic. No I/O. No framework dependencies. Depends on nothing.
                  - Application layer: orchestrates domain logic. Depends on domain. No I/O primitives.
                  - Infrastructure layer: implements traits defined in the domain. Depends on domain and application. Performs I/O.
                  - Presentation layer: HTTP handlers, CLI commands. Depends on application. Never directly on domain internals.
                  - Dependencies point inward. The domain never imports from infrastructure. Infrastructure imports from domain.

                  ---

                  ### Struct Arguments — Functions Take At Most One Non-Self Parameter

                  Every function taking more than one non-`self` parameter is wrong by default. The extra parameters belong together in a struct. This is not a style preference. It is an architectural rule. Multiple bare parameters signal that the caller must know the correct order, the correct meaning of each position, and the correct types — all without names. A struct gives every parameter a name at the call site.

                  **The hard limit:**
                  - Zero parameters: always fine.
                  - One parameter: always fine.
                  - Two parameters: acceptable when the two values are genuinely independent and have no thematic relationship. `fn zip<A, B>(first: A, second: B)` — independent by definition.
                  - Three or more parameters: define a struct. No exceptions. `&self` or `&mut self` does not count.

                  **Defining the parameter struct:**
                  - Name it after the operation and what it configures: `CreateUserRequest`, `SendEmailParams`, `QueryOptions`, `RenderConfig`, `ConnectionSettings`.
                  - It implements `Debug` always.
                  - It implements `Default` when any parameters are optional with sensible defaults.
                  - It implements `Clone` when it might be reused.
                  - Optional parameters are `Option<T>` fields with `#[serde(default)]` if serialized, resolved to defaults in the function body.
                  - The struct is defined in the same module as the function.
                  - Wrong: `fn create_user(name: String, email: String, role: Role, notify: bool, created_by: UserId) -> Result<UserId, CreateUserError>`.
                  - Right:
                    ```
                    struct CreateUserRequest {
                        name: Name,
                        email: EmailAddress,
                        role: Role,
                        send_welcome_email: bool,
                        created_by: UserId,
                    }
                    fn create_user(request: CreateUserRequest) -> Result<UserId, CreateUserError>
                    ```

                  **Two-parameter functions that are NOT acceptable:**
                  - Two `String` parameters: always a struct. `fn rename(old: String, new: String)` → `struct RenameRequest { old_name: Name, new_name: Name }`.
                  - Two `bool` parameters: always a struct or an enum. Booleans have no names at call sites.
                  - A domain type plus a primitive: often a struct. `fn schedule(task: Task, delay: Duration)` — if there are ever more scheduling options, this grows. Start with a struct.
                  - A key plus a value: the one genuine exception. `fn insert(key: K, value: V)` is established convention.

                  **Builder vs. parameter struct:**
                  - Parameter structs are for simple cases where all or most parameters are required.
                  - Builders are for cases where there are many optional parameters, where parameters have dependencies on each other, or where invalid combinations must be rejected at compile time.
                  - A parameter struct with more than five fields should probably be a builder.

                  ---

                  ### Type Algebra — Using the Type System as a Proof System

                  The Rust type system is a theorem prover. Every type is a proposition. Every value of that type is a proof that the proposition holds. Design types to encode the proofs your domain requires.

                  **Phantom types for unit safety:**
                  - Every numeric value with a unit is a generic struct over a unit marker type.
                  - `struct Quantity<Unit> { value: f64, _unit: PhantomData<Unit> }`.
                  - `struct Meters;` `struct Feet;` `struct Seconds;` `struct Kilograms;`.
                  - `Quantity<Meters>` and `Quantity<Feet>` cannot be added. Compile error. The Mars Climate Orbiter crashed because of a unit mismatch that a type system could have caught. This type system can catch it.
                  - Conversion: `impl From<Quantity<Feet>> for Quantity<Meters> { fn from(q: Quantity<Feet>) -> Self { Quantity { value: q.value * 0.3048, _unit: PhantomData } } }`. One place. One constant. One `From` impl.
                  - `impl<Unit> Add for Quantity<Unit> { type Output = Self; fn add(self, rhs: Self) -> Self { Quantity { value: self.value + rhs.value, _unit: PhantomData } } }`. Adding same-unit quantities is addition. Adding different-unit quantities is a compile error.

                  **Refinement types — values with proven invariants:**
                  - `struct NonEmptyVec<T> { first: T, rest: Vec<T> }`. Always has at least one element. The type makes it impossible to construct an empty instance. Every function requiring a non-empty list accepts `NonEmptyVec<T>`, not `Vec<T>`. `first()` and `last()` return `T`, not `Option<T>`.
                  - `struct BoundedU32<const MIN: u32, const MAX: u32> { value: u32 }`. A number proven to be within `[MIN, MAX]`. Constructor returns `Result<Self, OutOfRangeError>`.
                  - `struct Positive(f64)`. A float proven positive. `sqrt()` is infallible on `Positive`. No need for `f64::sqrt` which returns `NaN` for negative inputs.
                  - `struct SortedVec<T: Ord> { inner: Vec<T> }`. A vec proven sorted. Binary search is always valid. The type guarantees the precondition.
                  - `struct Normalized(f64)`. A float proven in `[0.0, 1.0]`. Percentage operations are safe.

                  **Witness types:**
                  - A witness type is a zero-cost proof that an operation was performed.
                  - `struct Validated<T> { inner: T }`. Constructible only by calling `validate(value) -> Result<Validated<T>, ValidationError>`. Functions requiring validated input accept `Validated<T>`, not `T`. Unvalidated values cannot reach these functions.
                  - `struct Authenticated<T> { inner: T }`. Constructible only via `authenticate(...)`. Functions requiring authentication accept `Authenticated<Request>`.
                  - `struct Authorized<Permission, T> { inner: T, _permission: PhantomData<Permission> }`. Constructible only via `authorize::<CreateUser>(actor)`. Functions requiring a specific permission accept `Authorized<CreateUser, Actor>`.
                  - Witnesses are zero-sized when the wrapped type is stateless. The entire authorization model compiles to nothing at runtime.

                  **Branded types for taint tracking:**
                  - A branded type marks the provenance of a value. `struct Untrusted<T>(T)`. Raw user input is always `Untrusted<String>`. Functions that sanitize input accept `Untrusted<String>` and return `Sanitized<String>`. Functions that are SQL-injection-safe accept only `Sanitized<String>`. An unsanitized string cannot reach a SQL query — the type prevents it.
                  - `struct FromDatabase<T>(T)`. Values read from the database are `FromDatabase<T>`. Functions that expect database-sourced data accept `FromDatabase<T>`. A value constructed from user input that was not persisted and re-read cannot be passed as a `FromDatabase<T>`.
                  - The compiler enforces the data flow. No runtime checks needed.

                  **Session types for protocol safety:**
                  - A session type encodes a communication protocol in the type system. Each step of the protocol is a type transition. Skipping a step is a compile error.
                  - `struct Handshaking;` `struct Authenticated;` `struct RequestSent;` `struct ResponseReceived;`.
                  - `struct TlsConnection<State> { stream: TcpStream, _state: PhantomData<State> }`.
                  - `impl TlsConnection<Handshaking> { fn complete_handshake(self) -> Result<TlsConnection<Authenticated>, TlsError> }`.
                  - `impl TlsConnection<Authenticated> { fn send_request(self, request: Request) -> Result<TlsConnection<RequestSent>, NetworkError> }`.
                  - `impl TlsConnection<RequestSent> { fn receive_response(self) -> Result<(TlsConnection<ResponseReceived>, Response), NetworkError> }`.
                  - Sending a request before the handshake completes: compile error. Receiving a response before sending a request: compile error. The entire protocol is enforced statically.

                  ---

                  ### State Machine Design Deep Reference

                  **Enum state machines — when and how:**
                  - Use an enum state machine when: the state must be persisted or serialized, multiple threads may observe the state, the state must be readable at runtime, or the number of transitions is large.
                  - Each enum variant holds exactly the data valid in that state — no more, no less. If the `Shipped` state does not yet know the `delivered_at` timestamp, it has no `delivered_at` field. This is the entire point.
                  - Transition methods consume `self`: `fn confirm(self, ...) -> Result<Self, TransitionError>`. They return `Result` because runtime validation may fail.
                  - The `match` on the current state inside a transition method is exhaustive and handles every valid transition.

                  **Type-state machines — when and how:**
                  - Use type-state when: the state is transient (not persisted), the transitions are statically known and few, and compile-time enforcement is more valuable than runtime flexibility.
                  - Zero-sized state marker types: `struct Uninitialized;` `struct Ready;` `struct Running;` `struct Stopped;`. These have no runtime cost.
                  - `PhantomData<State>` in the generic struct: zero runtime cost, carries the type.
                  - Each state's `impl` block contains only the methods valid in that state. Calling an invalid method is a compile error — not a runtime error, not a logged warning, a compile error.
                  - State transitions consume the struct: `fn start(self) -> Machine<Running>`. The old state is gone. You cannot use the stopped machine after starting it.

                  **Combining both:**
                  - An outer type-state for coarse lifecycle phases (constructed, running, shut down).
                  - An inner enum for fine-grained runtime states within a phase.
                  - Example: `struct Server<Phase>`. `Phase` is `Configuring`, `Running`, `ShuttingDown`. Within `Running`, an inner enum tracks `Idle`, `ProcessingRequest(RequestId)`, `WritingResponse(RequestId)`.

                  **The state machine as a design tool:**
                  - Before writing any type with mutable state, draw the state machine. What are the states? What are the valid transitions? What data is valid in each state?
                  - If the state machine has more than 7 states, it is too complex. Split it.
                  - If the state machine has a transition that can reach any state from any state, it is not a state machine — it is unstructured state mutation. Redesign.
                  - Every `Option` field in a struct is a hidden two-state machine. Make it explicit.
                  - Every `bool` field in a struct is a hidden two-state machine. Make it explicit.
                  - A struct with three `bool` fields is a hidden eight-state machine. Make it explicit. Most of those eight states are probably invalid — express the valid ones as enum variants.

                  ---

                  ### Function Design Deep Reference

                  **What a function is:**
                  - A function is a named unit of computation. Its name is a proposition: "given these inputs, this function produces this output." The body is the proof.
                  - A function exists because the computation it performs has a name. Not because the code was long. Not because it is called twice. Because the computation is a named concept in the domain.
                  - If you extract a function and cannot name it without using "and" ("validate_and_transform", "fetch_and_process") — you extracted two functions. Split further.

                  **Hard limits:**
                  - 40 lines maximum. Hard. No exceptions.
                  - Cyclomatic complexity 5 maximum. More than 5 branches: extract named helpers.
                  - 2 non-self parameters maximum. More: define a struct.
                  - 0 nested closures. A closure inside a closure is always a named function.
                  - 0 functions with "and" or "or" in their name. One function, one thing.

                  **Recursion:**
                  - Only for genuinely recursive structures (trees, graphs, grammars) where the depth is bounded or the problem is explicitly recursive.
                  - Unbounded user-controlled recursion is a stack overflow attack surface. Convert to iteration with an explicit `Vec` stack.
                  - Tail recursion is not guaranteed to optimize. Use iteration.

                  **Associated functions vs. methods:**
                  - Methods take `&self`, `&mut self`, or `self`. They operate on an existing instance.
                  - Associated functions do not take `self`. They are constructors, converters, or utilities tied to the type by ownership.
                  - Free functions outside any `impl` block: almost never correct. The one exception in non-`main` code: a pure mathematical function with no type affinity (`fn gcd(a: u64, b: u64) -> u64`).
                  - When in doubt: if the function takes any value of a specific type as a primary input, it is a method or associated function on that type.

                  **`impl` block organization within a file:**
                  All `impl TypeName` blocks follow this order:
                  1. Constructors: `new`, `try_new`, `with_capacity`, `from_*`, `default` (if manual).
                  2. Property accessors (read-only): `&self` methods returning field values or derived values.
                  3. Predicates: `&self` methods returning `bool`.
                  4. Mutators: `&mut self` methods modifying state.
                  5. Consumers: `self` methods consuming the value.
                  6. Associated functions: no `self` parameter, not constructors.
                  7. Trait implementations: one `impl TraitName for TypeName` block per trait, grouped after all inherent impls.
                  Conversion traits: `From`, `TryFrom`, `FromStr`, `AsRef`, `Borrow`.
                  Formatting traits: `Display` (if not derived), `Debug` (if not derived).
                  Operator traits: `Add`, `Sub`, `Mul`, `Neg`, `Index`, etc.
                  Iterator traits: `Iterator`, `IntoIterator`, `FromIterator`, `Extend`.
                  Other standard traits in alphabetical order.
                  8. `#[cfg(test)] mod tests { ... }` at the very bottom.

                  ---

                  ### Ownership Patterns Deep Reference

                  **The ownership decision tree:**
                  - Does the function need to read the value? → `&T`.
                  - Does the function need to modify the value and the caller wants to keep it? → `&mut T`.
                  - Does the function need to store the value or will it outlive the function? → `T` (transfer ownership).
                  - Does the function need to share the value across threads? → `Arc<T>`.
                  - Is the decision between `&T` and `T` being driven by the borrow checker rather than semantics? → the ownership design is wrong. Fix the structure.

                  **RAII everywhere:**
                  - Every resource acquisition is tied to a constructor. Every resource release is in `Drop`.
                  - File opened in `new()`, closed in `drop()`.
                  - Lock acquired in constructor, released in `drop()`.
                  - Database connection checked out in constructor, returned to pool in `drop()`.
                  - Network connection established in `connect()`, torn down in `drop()`.
                  - There is no "remember to call `close()`" in Rust. If `close()` must be called, the type forces it via `Drop`.
                  - `impl Drop for MyResource { fn drop(&mut self) { /* release resource */ } }`. This is not optional for types that hold resources.
                  - When teardown can fail, provide `fn close(self) -> Result<(), Error>`. If the caller does not call `close()`, `Drop` runs and silently handles or logs the error.

                  **Borrow splitting:**
                  - The borrow checker prevents multiple mutable borrows to the same struct simultaneously.
                  - When you need to mutate two different fields of a struct simultaneously, the struct splits them into sub-structs or uses interior mutability.
                  - `struct Config { display: DisplayConfig, network: NetworkConfig }`. You can borrow `config.display` mutably while borrowing `config.network` immutably. The borrow checker understands field borrows.
                  - A struct that cannot be borrowed in parts is a design smell. Reorganize the fields into coherent sub-structs.

                  **`Pin` and self-referential types:**
                  - `Pin<P>` prevents the value pointed to by `P` from being moved in memory.
                  - Self-referential structs (structs containing a reference to themselves) require `Pin`.
                  - Async futures are self-referential and require `Pin`. This is handled automatically by `async`/`.await`.
                  - Manual self-referential structs use the `pin-project` crate for safe field projection.
                  - `Box::pin(value)` to create a pinned heap allocation.
                  - `std::pin::pin!(value)` to create a pinned stack value (nightly or via `tokio::pin!`).

                  ---

                  ### API Stability and Evolution

                  **Semver discipline:**
                  - Patch version (1.0.x): bug fixes only. No new public API. No behavioral changes observable by correct code.
                  - Minor version (1.x.0): new public API, all backward-compatible. New `pub` items, new trait implementations, new enum variants on `#[non_exhaustive]` enums.
                  - Major version (x.0.0): breaking changes. Removed items, changed signatures, non-`#[non_exhaustive]` enum variants added, sealed trait unsealed.
                  - Adding a `pub` function: minor version.
                  - Changing a `pub` function signature: major version.
                  - Adding a field to a `#[non_exhaustive]` struct: minor version.
                  - Adding a field to a non-`#[non_exhaustive]` struct: major version.
                  - Adding a variant to a `#[non_exhaustive]` enum: minor version.
                  - Adding a variant to a non-`#[non_exhaustive]` enum: major version.
                  - Implementing a new standard library trait for an existing type: minor version (can break downstream code that provides its own impl — use `#[non_exhaustive]` carefully).

                  **Deprecation before removal:**
                  - `#[deprecated(since = "1.2.0", note = "use new_method() instead")]` marks old items.
                  - Deprecated items are removed in the next major version.
                  - The deprecation note always specifies what to use instead.
                  - Never remove without deprecation first, except in major version zero (`0.x.y`).

                  **`#[non_exhaustive]` everywhere:**
                  - Every `pub enum` in a library crate is `#[non_exhaustive]`. Without exception.
                  - Every `pub struct` that may gain fields is `#[non_exhaustive]`. When in doubt, add it.
                  - `#[non_exhaustive]` prevents downstream code from exhaustively matching your enum or constructing your struct. This is correct — downstream code should be resilient to additions.

                  ---

                  ### Conciseness Without Brevity

                  Rust code should be dense with meaning, not sparse with words. Every token earns its place by communicating something that could not be communicated more directly.

                  **Variable names are full and precise, but not verbose:**
                  - Not `the_user_that_sent_the_message` (verbose). Not `u` (meaningless). `message_sender` (precise).
                  - Not `the_result_of_the_database_query` (verbose). Not `res` (meaningless). `found_user` or `matching_orders` (precise).
                  - The name answers the question: what is this, in terms of the domain? Not: what type is this, in terms of Rust?

                  **One statement, one fact:**
                  - Each `let` binding establishes one fact about the current computation.
                  - Each method call in a chain performs one transformation.
                  - Each `match` arm handles one case.
                  - Combining multiple facts into one expression reduces readability even if it reduces line count.

                  **Prefer `?` chains to nested `match`:**
                  - Three nested `match` blocks checking for errors: rewrite as three `?` operators.
                  - But: each `?` is named. The value produced by each `?` has a name. The reader sees each step.

                  **No redundant type annotations:**
                  - When the type is obvious from the right-hand side, omit the annotation: `let user = User::new(...)` not `let user: User = User::new(...)`.
                  - When the type is not obvious, add the annotation: `let count = items.len()` is obvious. `let result = compute()` — if `compute()` returns an `i64` and that matters, write `let result: i64 = compute()`.
                  - Closure parameter types: add when the closure is stored or returned. Omit when the compiler infers them from context.

                  **Turbofish only when necessary:**
                  - `value.parse::<u64>()` — necessary when the type cannot be inferred.
                  - `items.collect::<Vec<_>>()` — necessary when the collection type is ambiguous.
                  - `items.collect::<HashSet<_>>()` — necessary.
                  - Never add a turbofish that the compiler would infer correctly without it.

                  ---

                  ## Parse Don't Validate — The Fundamental Boundary Rule

                  **The rule:** Never pass unvalidated data through your system. Parse inputs into precise types at the system boundary. After that boundary, the type is the proof. No re-checking, no `is_valid()` methods, no defensive guards in the middle of business logic.

                  **What this means concretely:**
                  - A function that receives a `String` email cannot trust it is a valid email. A function that receives an `EmailAddress` struct can. The struct's constructor is the only place validation happens.
                  - `Option<T>` means absent. `Result<T, E>` means failure. A non-empty `Vec<T>` where you need at least one element is wrong — define `NonEmptyVec<T>`.
                  - Validated types must be constructed only through constructors that can fail. The failing constructor is `TryFrom` or a named constructor like `new()` that returns `Result<Self, E>`. After construction, the value is always valid.

                  **The wrong way:**
                  ```rust
                  fn create_user(email: String, age: u32) -> Result<User, Error> {
                      if !email.contains('@') {
                          return Err(Error::InvalidEmail);
                      }
                      if age < 18 {
                          return Err(Error::TooYoung);
                      }
                      // ... more validation scattered here
                  }
                  ```

                  **The right way:**
                  ```rust
                  struct EmailAddress(String);

                  impl TryFrom<String> for EmailAddress {
                      type Error = InvalidEmailError;
                      fn try_from(raw: String) -> Result<Self, Self::Error> {
                          if !raw.contains('@') {
                              return Err(InvalidEmailError::MissingAtSign);
                          }
                          Ok(Self(raw))
                      }
                  }

                  struct Age(u32);

                  impl TryFrom<u32> for Age {
                      type Error = InvalidAgeError;
                      fn try_from(value: u32) -> Result<Self, Self::Error> {
                          if value < 18 {
                              return Err(InvalidAgeError::BelowMinimum { actual: value, minimum: 18 });
                          }
                          Ok(Self(value))
                      }
                  }

                  fn create_user(email: EmailAddress, age: Age) -> User {
                      // No validation here. Types guarantee correctness.
                      User::new(email, age)
                  }
                  ```

                  **Rules for boundary types:**
                  - Every type that wraps a primitive and adds invariants must have `TryFrom` as its primary constructor.
                  - The inner value must not be `pub`. Expose it via a getter that returns `&str`, `u32`, etc.
                  - Implement `Display` to show the inner value. Implement `Debug` via derive.
                  - Do not implement `From<String>` for a validated type — `From` is infallible, and validation is fallible.
                  - Do not expose `as_inner()` or `into_inner()` unless the consuming code genuinely needs the raw value. When you do expose it, name the method after the semantic concept: `.as_str()` not `.as_inner()`.

                  **Carry invariants in the type system:**
                  - `NonEmpty<T>` for collections that must have at least one element.
                  - `Positive<f64>` for positive floats.
                  - `Normalized<Vec3>` for unit vectors.
                  - `Sorted<Vec<T>>` for pre-sorted collections.
                  - `Validated<T>` for types that passed external validation. Use this wrapper pattern when validation cost is significant and you want to avoid repeating it.

                  **Deserialization is a boundary:**
                  - Serde deserialization is a system boundary. Types deserialized from JSON, TOML, env vars, databases must either be parsed into validated types during deserialization (via `#[serde(try_from = "String")]`) or go through explicit construction after deserialization.
                  - Never deserialize into `String` and then validate later in application code. Deserialize directly into `EmailAddress`, `Url`, `Duration`, etc.

                  ```rust
                  #[derive(Deserialize)]
                  struct UserRequest {
                      #[serde(try_from = "String")]
                      email: EmailAddress,
                      #[serde(try_from = "u32")]
                      age: Age,
                  }
                  ```

                  ---

                  ## Witness Types and Proof-Carrying Code

                  A witness type proves a fact to the compiler without carrying data. Zero-sized types are the most powerful tool for encoding invariants that span function boundaries.

                  **The core pattern:**
                  ```rust
                  use std::marker::PhantomData;

                  struct Verified;
                  struct Unverified;

                  struct Token<State> {
                      value: String,
                      _state: PhantomData<State>,
                  }

                  impl Token<Unverified> {
                      fn new(value: String) -> Self {
                          Self { value, _state: PhantomData }
                      }

                      fn verify(self, secret: &str) -> Result<Token<Verified>, VerificationError> {
                          if hmac_verify(&self.value, secret) {
                              Ok(Token { value: self.value, _state: PhantomData })
                          } else {
                              Err(VerificationError::InvalidSignature)
                          }
                      }
                  }

                  impl Token<Verified> {
                      fn claims(&self) -> &str {
                          &self.value
                      }
                  }

                  // This function can ONLY be called with a verified token — enforced at compile time.
                  fn protected_endpoint(token: Token<Verified>) -> Response {
                      // ...
                  }
                  ```

                  **When to use witness types:**
                  - Authentication and authorization: `Authenticated<Request>` vs `Unauthenticated<Request>`.
                  - Database transactions: `Transactional<Conn>` vs `NonTransactional<Conn>`.
                  - Sorted collections: `Sorted<Vec<T>>` — the wrapper proves the invariant.
                  - Initialized resources: `Initialized<Service>` vs `Uninitialized<Service>`.
                  - Ownership transfer in protocols: state machine transitions where the old state must not be usable after transition.

                  **Rules:**
                  - The phantom type parameter must be `PhantomData<State>`, not stored as a field value.
                  - State marker types are usually ZSTs: `struct Verified;`.
                  - Use sealed traits if you want to restrict which states are externally constructible.
                  - The transition function consumes `self` (takes ownership) and returns the new state. This makes it impossible to use the old state after transition.
                  - If a proof type carries a lifetime, use `PhantomData<&'a State>` to tie the proof to the lifetime of the underlying resource.

                  **Proof-carrying code:**
                  ```rust
                  struct NonEmpty;
                  struct MaybeEmpty;

                  struct Collection<Contents, Populated> {
                      items: Vec<Contents>,
                      _populated: PhantomData<Populated>,
                  }

                  impl<T> Collection<T, MaybeEmpty> {
                      fn new() -> Self {
                          Self { items: Vec::new(), _populated: PhantomData }
                      }

                      fn push(mut self, item: T) -> Collection<T, NonEmpty> {
                          self.items.push(item);
                          Collection { items: self.items, _populated: PhantomData }
                      }
                  }

                  impl<T> Collection<T, NonEmpty> {
                      fn first(&self) -> &T {
                          &self.items[0] // Safe: NonEmpty witness guarantees at least one element.
                      }
                  }
                  ```

                  ---

                  ## Extension Traits — The FooExt Pattern

                  When you want to add methods to a type you do not own, or to a trait you do not own, use an extension trait. Extension traits follow the `FooExt` naming convention.

                  **The pattern:**
                  ```rust
                  pub trait StrExt {
                      fn to_title_case(&self) -> String;
                      fn word_count(&self) -> usize;
                  }

                  impl StrExt for str {
                      fn to_title_case(&self) -> String {
                          // implementation
                      }

                      fn word_count(&self) -> usize {
                          self.split_whitespace().count()
                      }
                  }
                  ```

                  **Sealed extension traits — prevent external implementation:**
                  When an extension trait is an implementation detail and must not be implemented by downstream code, seal it.

                  ```rust
                  mod private {
                      pub trait Sealed {}
                  }

                  pub trait ResultExt: private::Sealed {
                      fn log_error(self) -> Self;
                  }

                  impl<T, E: std::fmt::Display> private::Sealed for Result<T, E> {}

                  impl<T, E: std::fmt::Display> ResultExt for Result<T, E> {
                      fn log_error(self) -> Self {
                          if let Err(ref error) = self {
                              tracing::error!("{error}");
                          }
                          self
                      }
                  }
                  ```

                  **Rules for extension traits:**
                  - Name: `{TypeBeingExtended}Ext`. `StrExt`, `SliceExt`, `ResultExt`, `FutureExt`, `StreamExt`.
                  - Live in their own module, typically `ext.rs` or a submodule of the crate root.
                  - Extension traits that are implementation details must be sealed with the private module pattern.
                  - Extension traits that are part of the public API must be documented with `//!` at module level.
                  - Do not implement extension traits for types that already have the method via another path — extension methods shadow inherent methods and cause confusing resolution.
                  - A sealed extension trait's `Sealed` supertrait lives in a private module. The name `private::Sealed` is conventional and must not change.
                  - Blanket implementations (`impl<T: SomeTrait> FooExt for T`) are acceptable for extension traits. They must be written after the trait definition, in the same module.

                  ---

                  ## Typed Index Pattern — Never Use Raw usize

                  Raw `usize` indices are anonymous. They mix with every other `usize`. They can be confused with lengths, offsets, capacities. Define typed wrappers for every index type.

                  **The wrong way:**
                  ```rust
                  fn get_node(nodes: &[Node], index: usize) -> &Node {
                      &nodes[index]
                  }
                  ```

                  **The right way:**
                  ```rust
                  struct NodeIndex {
                      index: usize,
                  }

                  impl NodeIndex {
                      fn new(index: usize) -> Self {
                          Self { index }
                      }

                      fn as_usize(&self) -> usize {
                          self.index
                      }
                  }

                  fn get_node<'graph>(nodes: &'graph [Node], index: NodeIndex) -> &'graph Node {
                      &nodes[index.as_usize()]
                  }
                  ```

                  **Rules for typed indices:**
                  - Every arena, pool, slotmap, or indexed collection has its own distinct index type.
                  - `NodeIndex` and `EdgeIndex` are different types even if both wrap `usize`. You cannot accidentally pass an `EdgeIndex` where a `NodeIndex` is expected.
                  - The index type is constructed only by the collection that owns the data. The collection returns `NodeIndex` from insertion methods. External code cannot construct arbitrary `NodeIndex` values.
                  - To prevent external construction, make the inner field private and expose no public constructor. The collection owns the constructor.
                  - Implement `Copy` for index types — they are small and cheap to copy.
                  - Implement `Debug`, `Eq`, `Hash`, `Ord`, `PartialEq`, `PartialOrd` via derive.
                  - Do not implement arithmetic on index types. `index + 1` should not compile. Use named methods like `.next()` if increment is needed.

                  **SlotMap pattern:**
                  When using `slotmap` crate, define typed keys:
                  ```rust
                  use slotmap::new_key_type;

                  new_key_type! {
                      struct NodeKey;
                      struct EdgeKey;
                  }
                  ```
                  `NodeKey` and `EdgeKey` are incompatible. Passing the wrong key type is a compile error.

                  **Generational indices:**
                  For arenas that support removal and reuse of slots, generational indices prevent use-after-free:
                  - Store a generation counter alongside the index.
                  - When a slot is freed and reused, its generation increments.
                  - An old index with an outdated generation returns `None` instead of the new occupant.
                  - This logic is encapsulated in the arena type. The caller never sees generations — they see `Option<&T>`.

                  ---

                  ## Zero-Copy Design

                  Allocations are never free. Every `String`, every `Vec<T>`, every `Box<T>` is a heap allocation. Prefer borrowed types when ownership is not required.

                  **Function signatures prefer borrows:**
                  - Accept `&str` not `String`. Accept `&[T]` not `Vec<T>`. Accept `&Path` not `PathBuf`.
                  - Return owned types when the caller needs to keep the value. Return borrows when the return value is derived from an input.
                  - `String` is an owned buffer. `&str` is a view into one. A function that searches for a substring returns `&str`, not `String`.

                  **Cow for conditionally owned data:**
                  ```rust
                  use std::borrow::Cow;

                  fn normalize_path(input: &str) -> Cow<str> {
                      if input.starts_with('/') {
                          Cow::Borrowed(input)
                      } else {
                          Cow::Owned(format!("/{input}"))
                      }
                  }
                  ```
                  `Cow` avoids an allocation when the data does not need transformation. Use it in:
                  - Functions that sometimes need to modify the input and sometimes can return it as-is.
                  - Error messages that are sometimes static strings and sometimes formatted.
                  - Deserialization where many values are unchanged from the input buffer.

                  **Zero-copy deserialization:**
                  When deserializing from a buffer that lives at least as long as the deserialized value, borrow from the buffer instead of copying:
                  ```rust
                  #[derive(Deserialize)]
                  struct Message<'de> {
                      #[serde(borrow)]
                      content: &'de str,
                      #[serde(borrow)]
                      author: &'de str,
                  }
                  ```
                  The `'de` lifetime ties the deserialized struct to the input buffer. Content is not copied — the `&str` fields point directly into the buffer.

                  **Rules:**
                  - Never clone a value just to pass it to a function. Borrow it instead. If you write `.clone()` to satisfy a borrow checker error, the function signature is wrong — change it to accept a borrow.
                  - `Arc<str>` instead of `String` when the same string is shared across threads without mutation.
                  - `Arc<[T]>` instead of `Vec<T>` for shared immutable slices.
                  - Avoid `to_string()` inside hot loops. Compute the string once, outside the loop.
                  - `Bytes` from the `bytes` crate for cheap cloning of byte buffers — `Bytes` is `Arc`-backed and cloning it only increments a reference count.

                  ---

                  ## Interior Mutability — Decision Tree

                  Interior mutability is the escape hatch from the borrow checker's single-writer rule. Use it only when the borrow checker's model is genuinely insufficient. Every use of interior mutability is a trade: compile-time safety for runtime checking.

                  **The decision tree:**

                  1. Do you need mutation at all? If not, use `&T`.
                  2. Is mutation exclusive and always safe to model with `&mut T`? Use `&mut T`.
                  3. Is the value `Copy` and shared between threads? Use `AtomicBool`, `AtomicU64`, etc.
                  4. Is the value `Copy` and single-threaded? Use `Cell<T>`.
                  5. Is the value non-Copy and single-threaded, mutation is infrequent, and you accept runtime panics on aliased mutation? Use `RefCell<T>`.
                  6. Is the value shared between threads with infrequent writes and many readers? Use `RwLock<T>`.
                  7. Is the value shared between threads with balanced reads and writes? Use `Mutex<T>`.
                  8. Does the value need to be initialized exactly once after program start? Use `OnceLock<T>` (thread-safe) or `OnceCell<T>` (single-threaded).
                  9. Does the value need lazy initialization from a closure? Use `LazyLock<T>` (thread-safe) or `LazyCell<T>` (single-threaded).

                  **Cell<T>:**
                  - Only for `Copy` types.
                  - Single-threaded only (`!Sync`).
                  - No borrow overhead — moves values in and out.
                  - Use for: counters, flags, small values mutated frequently in single-threaded contexts.
                  - Do not wrap `String` or `Vec` in `Cell` — they are not `Copy`. Use `RefCell` instead.

                  **RefCell<T>:**
                  - Runtime borrow checking. Panics if borrows conflict.
                  - Single-threaded only (`!Sync`).
                  - Use for: tree nodes with parent pointers, observers, graph structures where shared mutable access is required.
                  - Always keep borrows short-lived. Never store a `Ref<T>` or `RefMut<T>` across a function boundary.
                  - If your code is reaching for `RefCell` frequently, reconsider the ownership model.

                  **Mutex<T>:**
                  - Runtime exclusion. Blocks threads waiting for the lock.
                  - Use for: shared mutable state between threads where writes are as frequent as reads.
                  - Always lock with `let guard = mutex.lock().unwrap()`. Never hold a guard longer than necessary.
                  - Never call async code while holding a `std::sync::Mutex` guard. Use `tokio::sync::Mutex` in async contexts.
                  - Poison on panic: if a thread panics while holding a `Mutex`, subsequent calls to `lock()` return `Err`. Handle this explicitly or call `.unwrap()` with awareness of the implication.

                  **RwLock<T>:**
                  - Multiple concurrent readers or one exclusive writer.
                  - Use when reads vastly outnumber writes.
                  - Writer starvation is possible on some implementations. Know your platform.
                  - In async contexts, use `tokio::sync::RwLock`.

                  **OnceLock<T> and OnceCell<T>:**
                  - Initialized at most once. After initialization, it is effectively immutable.
                  - `OnceLock<T>`: thread-safe, use for global configuration, registry, plugin tables.
                  - `OnceCell<T>`: single-threaded, use for lazy struct fields.
                  - Prefer `OnceLock` over `static mut` for static initialization. `static mut` is almost always wrong.

                  **Rules:**
                  - Never wrap `Mutex<Option<T>>` to represent optional state. Use a proper state enum.
                  - Never nest locks: `Mutex<HashMap<K, Mutex<V>>>` is a deadlock waiting to happen. Restructure data.
                  - Atomic types for single values only. `AtomicU64` for a counter. Not `AtomicPtr` for a complex structure — use a `Mutex` or `RwLock` there.
                  - Document every use of interior mutability with a comment stating why `&mut T` was insufficient.

                  ---

                  ## Static Assertions — Compile-Time API Contracts

                  Use the `static_assertions` crate to encode invariants that must hold forever. Static assertions fail at compile time — they cannot be forgotten, they cannot pass on one platform and fail on another.

                  **Required in every crate that exports public types:**
                  ```rust
                  #[cfg(test)]
                  mod assertions {
                      use static_assertions::{assert_impl_all, assert_not_impl_any, const_assert};

                      assert_impl_all!(MyType: Send, Sync);
                      assert_impl_all!(MyError: std::error::Error, Send, Sync, 'static);
                      assert_not_impl_any!(MyHandle: Clone);
                      const_assert!(std::mem::size_of::<MyType>() <= 64);
                  }
                  ```

                  **assert_impl_all! — require trait implementations:**
                  Every public type that crosses thread boundaries must assert `Send + Sync`. Every error type that is returned across async boundaries must assert `Send + Sync + 'static`. These assertions catch accidental removal of `Send`/`Sync` impls.

                  **assert_not_impl_any! — prohibit trait implementations:**
                  Types that must not be cloned (handles, file descriptors, unique tokens) must assert `!Clone`. Types that must remain single-threaded must assert `!Send` or `!Sync`. This prevents accidental `derive(Clone)` from breaking invariants.

                  **const_assert! — numeric invariants:**
                  Size limits, alignment requirements, enum discriminant values — these are things that must not change silently:
                  ```rust
                  const_assert!(std::mem::size_of::<PacketHeader>() == 20);
                  const_assert!(std::mem::align_of::<DmaBuffer>() >= 64);
                  const_assert!(MAX_CONNECTIONS <= 65535);
                  ```

                  **assert_eq_size! — layout compatibility:**
                  When two types must have the same size for FFI, transmute, or protocol correctness:
                  ```rust
                  assert_eq_size!(WireHeader, [u8; 16]);
                  ```

                  **Placement:**
                  - Static assertions for public API contracts live in `src/lib.rs` or `src/assertions.rs` in a `#[cfg(test)]` module named `static_assertions`.
                  - Static assertions for a specific module's invariants live in that module, also in `#[cfg(test)]`.
                  - Every public struct, enum, and trait that has size or trait requirements has at minimum one `assert_impl_all!`.

                  ---

                  ## Advanced Builder Typestate — Required Fields at Compile Time

                  Standard builders using `Option` fields allow constructing invalid objects at runtime: the caller forgets a required field and gets a runtime error. Typestate builders push this error to compile time.

                  **The problem with runtime builders:**
                  ```rust
                  // BAD: Missing required field is a runtime error.
                  let server = ServerBuilder::new()
                      .port(8080)
                      .build() // Panics: host not set
                      .unwrap();
                  ```

                  **The typestate builder:**
                  ```rust
                  struct NoHost;
                  struct WithHost(String);
                  struct NoPort;
                  struct WithPort(u16);

                  struct ServerBuilder<H, P> {
                      host: H,
                      port: P,
                      timeout_seconds: u64,
                  }

                  impl ServerBuilder<NoHost, NoPort> {
                      fn new() -> Self {
                          Self {
                              host: NoHost,
                              port: NoPort,
                              timeout_seconds: 30,
                          }
                      }
                  }

                  impl<P> ServerBuilder<NoHost, P> {
                      fn host(self, host: String) -> ServerBuilder<WithHost, P> {
                          ServerBuilder {
                              host: WithHost(host),
                              port: self.port,
                              timeout_seconds: self.timeout_seconds,
                          }
                      }
                  }

                  impl<H> ServerBuilder<H, NoPort> {
                      fn port(self, port: u16) -> ServerBuilder<H, WithPort> {
                          ServerBuilder {
                              host: self.host,
                              port: WithPort(port),
                              timeout_seconds: self.timeout_seconds,
                          }
                      }
                  }

                  impl<H, P> ServerBuilder<H, P> {
                      fn timeout(mut self, seconds: u64) -> Self {
                          self.timeout_seconds = seconds;
                          self
                      }
                  }

                  impl ServerBuilder<WithHost, WithPort> {
                      fn build(self) -> Server {
                          Server::new(self.host.0, self.port.0, self.timeout_seconds)
                      }
                  }
                  ```

                  Now `build()` only exists when both `host` and `port` have been set. Forgetting either is a compile error, not a runtime panic.

                  **Rules for typestate builders:**
                  - Required fields use the `No{Field}` / `With{Field}` marker pattern.
                  - Optional fields with defaults use plain struct fields (not typestate).
                  - The `build()` method only exists on the fully-populated typestate variant.
                  - The marker types (`NoHost`, `WithHost`) are private to the module. They are not part of the public API.
                  - Phantom marker types must use `PhantomData` only when the marker carries no data. When the marker wraps the value (`WithHost(String)`), use a named-field newtype struct, not a phantom.
                  - Each setter consumes `self` and returns `Self` with the new typestate. This enforces that setting a field is a one-way transition.

                  ---

                  ## Tokio Structured Concurrency Deep Reference

                  Tokio tasks are cheap but not free. Unstructured spawning creates tasks with no owner, no cancellation, and no error propagation path. Structured concurrency means every spawned task has an owner that waits for it.

                  **JoinSet — owning a group of tasks:**
                  ```rust
                  use tokio::task::JoinSet;

                  async fn process_all(items: Vec<WorkItem>) -> Vec<Result<Output, WorkError>> {
                      let mut join_set = JoinSet::new();

                      for item in items {
                          join_set.spawn(async move { process_one(item).await });
                      }

                      let mut results = Vec::with_capacity(join_set.len());
                      while let Some(result) = join_set.join_next().await {
                          let output = result.expect("task must not panic");
                          results.push(output);
                      }
                      results
                  }
                  ```

                  **CancellationToken — cooperative cancellation:**
                  ```rust
                  use tokio_util::sync::CancellationToken;

                  struct WorkerPool {
                      cancellation_token: CancellationToken,
                      join_set: JoinSet<()>,
                  }

                  impl WorkerPool {
                      fn new() -> Self {
                          Self {
                              cancellation_token: CancellationToken::new(),
                              join_set: JoinSet::new(),
                          }
                      }

                      fn spawn_worker(&mut self, task: impl Future<Output = ()> + Send + 'static) {
                          let token = self.cancellation_token.clone();
                          self.join_set.spawn(async move {
                              tokio::select! {
                                  _ = token.cancelled() => {},
                                  _ = task => {},
                              }
                          });
                      }

                      async fn shutdown(mut self) {
                          self.cancellation_token.cancel();
                          while self.join_set.join_next().await.is_some() {}
                      }
                  }
                  ```

                  **Task naming:**
                  Name every spawned task with `task::Builder`:
                  ```rust
                  tokio::task::Builder::new()
                      .name("ingest-worker")
                      .spawn(ingest_loop(receiver))
                      .expect("task spawn must succeed");
                  ```
                  Named tasks appear in panic messages, tokio-console output, and traces.

                  **Rules:**
                  - Never call `tokio::spawn` at a point where the task cannot be awaited. Use `JoinSet::spawn` instead.
                  - `tokio::spawn` is acceptable only at the top level of a program (main function or its direct callees) where the task represents a long-running service that lives for the program's lifetime.
                  - Every `JoinSet` must be awaited to completion. Dropping a `JoinSet` cancels all tasks — do this intentionally, not by accident.
                  - Never hold a `std::sync::Mutex` across an `.await` point. Use `tokio::sync::Mutex` or restructure to drop the guard before `.await`.
                  - Use `tokio::select!` with a cancellation token branch, not a timeout that causes silent drops.
                  - `tokio::time::timeout` wraps a future. Never use `sleep` followed by a check — use `timeout`.
                  - Task-local storage with `tokio::task_local!` is acceptable for request-scoped data like trace IDs.
                  - Never use `std::thread::sleep` inside async code. Use `tokio::time::sleep`.
                  - Spawning blocking operations uses `tokio::task::spawn_blocking`. Never call blocking operations directly from async functions — it stalls the runtime.

                  **Channels:**
                  - `tokio::sync::mpsc` — many producers, one consumer. The standard channel for work distribution.
                  - `tokio::sync::broadcast` — one producer, many consumers. Use for event fanout.
                  - `tokio::sync::watch` — one writer, many readers of the latest value. Use for configuration updates.
                  - `tokio::sync::oneshot` — single value, single receiver. Use for request-response pairing.
                  - `std::sync::mpsc` is wrong in async code. Always use tokio channels in async contexts.
                  - Always set a bounded buffer size on `mpsc` channels. Unbounded channels hide backpressure problems.

                  ---

                  ## Web Service Patterns — axum and sqlx

                  **axum: State injection, extractors, error types**

                  Application state in axum is an `Arc`-wrapped struct. Never use global state (`static` variables). Inject everything through the state extractor.

                  ```rust
                  #[derive(Clone)]
                  struct AppState {
                      database: Arc<Database>,
                      config: Arc<AppConfig>,
                  }

                  async fn get_user(
                      State(state): State<AppState>,
                      Path(user_id): Path<UserId>,
                  ) -> Result<Json<UserResponse>, AppError> {
                      let user = state.database.find_user(user_id).await?;
                      let response = UserResponse::from(user);
                      Ok(Json(response))
                  }
                  ```

                  **Error handling in axum:**
                  Implement `IntoResponse` for your error type. Never return strings or status codes directly from handlers:
                  ```rust
                  struct AppError(anyhow::Error);

                  impl IntoResponse for AppError {
                      fn into_response(self) -> Response {
                          let status = StatusCode::INTERNAL_SERVER_ERROR;
                          let body = Json(ErrorBody::new(self.0.to_string()));
                          (status, body).into_response()
                      }
                  }

                  impl<E: Into<anyhow::Error>> From<E> for AppError {
                      fn from(error: E) -> Self {
                          Self(error.into())
                      }
                  }
                  ```

                  **Validation in axum:**
                  Use `axum-valid` or manual extraction. Never validate in handler bodies. Validation belongs in the extractor or in the domain type constructor.

                  **sqlx: Query patterns**

                  Always use the compile-time verified macros:
                  ```rust
                  async fn find_user(pool: &PgPool, user_id: UserId) -> Result<User, sqlx::Error> {
                      let row = sqlx::query_as!(
                          UserRow,
                          "SELECT id, email, created_at FROM users WHERE id = $1",
                          user_id.as_uuid()
                      )
                      .fetch_one(pool)
                      .await?;
                      Ok(User::from(row))
                  }
                  ```

                  **sqlx rules:**
                  - Always use `sqlx::query_as!` with a named row type. Never use `sqlx::query!` returning anonymous records in production code.
                  - Row types are separate from domain types. `UserRow` holds raw database values. `User` is the domain type. `From<UserRow> for User` performs the conversion.
                  - Database IDs are UUIDs. Never use serial integers as public-facing IDs.
                  - Transactions wrap multi-statement operations:
                  ```rust
                  let mut transaction = pool.begin().await?;
                  sqlx::query!("INSERT INTO ...").execute(&mut *transaction).await?;
                  sqlx::query!("UPDATE ...").execute(&mut *transaction).await?;
                  transaction.commit().await?;
                  ```
                  - Migrations live in `migrations/` directory. Never run `ALTER TABLE` manually. Every schema change is a numbered migration file.
                  - Pool configuration: always set `max_connections`, `min_connections`, `acquire_timeout`, `idle_timeout`.
                  - Never store `PgPool` in a global. Inject it through the application state.

                  ---

                  ## Property Testing with proptest

                  Unit tests verify specific examples. Property tests verify invariants across thousands of generated inputs. Both are required for correctness.

                  **Basic property test:**
                  ```rust
                  use proptest::prelude::*;

                  proptest! {
                      #[test]
                      fn parse_then_display_is_identity(raw in "[a-z]+@[a-z]+\\.[a-z]+") {
                          let email = EmailAddress::try_from(raw.clone()).unwrap();
                          prop_assert_eq!(email.to_string(), raw);
                      }
                  }
                  ```

                  **Custom strategies with prop_compose:**
                  When the generated type has domain-specific invariants, write a strategy:
                  ```rust
                  prop_compose! {
                      fn valid_age()(value in 18u32..=120) -> Age {
                          Age::try_from(value).unwrap()
                      }
                  }

                  prop_compose! {
                      fn valid_user()(
                          email in "[a-z]{3,10}@[a-z]{3,10}\\.[a-z]{2,4}",
                          age in valid_age(),
                      ) -> User {
                          let email_addr = EmailAddress::try_from(email).unwrap();
                          User::new(email_addr, age)
                      }
                  }
                  ```

                  **Arbitrary derive:**
                  For types where all values are valid, derive `Arbitrary`:
                  ```rust
                  #[derive(Debug, Arbitrary)]
                  struct Offset {
                      row: u32,
                      column: u32,
                  }
                  ```

                  **What to property test:**
                  - Roundtrip: parse then serialize equals original input.
                  - Idempotency: applying an operation twice equals applying it once.
                  - Commutativity: order of operations does not matter when it should not.
                  - Monotonicity: adding more data never decreases a count.
                  - Boundary conditions: the invariants of your validated types hold under all generated inputs.

                  **proptest rules:**
                  - Property tests live alongside unit tests, in the same `#[cfg(test)]` module.
                  - Use `prop_assert!` and `prop_assert_eq!`, not plain `assert!` — they generate shrinking-friendly failures.
                  - Set `proptest!` configuration with `ProptestConfig::with_cases(1000)` for thorough testing.
                  - Proptest seeds are deterministic by default. If a failure is found, the seed is printed — use it to reproduce.
                  - For state machines, use the `proptest-state-machine` extension.

                  ---

                  ## Benchmark Discipline with criterion

                  Benchmarks measure performance. Without them, optimizations are guesses. With them, regressions are caught before shipping.

                  **Basic benchmark:**
                  ```rust
                  use criterion::{black_box, criterion_group, criterion_main, Criterion};

                  fn bench_parse_email(criterion: &mut Criterion) {
                      let raw = "user@example.com";
                      criterion.bench_function("parse_email", |bencher| {
                          bencher.iter(|| EmailAddress::try_from(black_box(raw.to_string())))
                      });
                  }

                  criterion_group!(benches, bench_parse_email);
                  criterion_main!(benches);
                  ```

                  **Throughput measurement:**
                  ```rust
                  fn bench_serialize(criterion: &mut Criterion) {
                      let data = generate_test_data(1024);
                      let mut group = criterion.benchmark_group("serialize");
                      group.throughput(Throughput::Bytes(data.len() as u64));
                      group.bench_function("json", |bencher| {
                          bencher.iter(|| serde_json::to_vec(black_box(&data)))
                      });
                      group.bench_function("msgpack", |bencher| {
                          bencher.iter(|| rmp_serde::to_vec(black_box(&data)))
                      });
                      group.finish();
                  }
                  ```

                  **Rules:**
                  - Every public function in a performance-critical path has a benchmark.
                  - Always wrap inputs to the benchmarked function in `black_box()`. This prevents the compiler from optimizing away the computation.
                  - Use benchmark groups to compare alternatives: `BenchmarkGroup::bench_function` with the same input and different implementations.
                  - Set warm-up time and measurement time in `BenchmarkConfig` for stable results.
                  - Benchmark results are saved to `target/criterion/`. Commit the baseline. Regression detection compares against the saved baseline.
                  - Never benchmark in debug builds. Always benchmark with `--release`.
                  - Allocations inside the benchmarked closure skew results. Measure allocation counts separately with `dhat` or `heaptrack`.

                  ---

                  ## Cargo Workspace Rules

                  **Workspace layout (flat, matklad style):**
                  ```
                  workspace-root/
                  ├── Cargo.toml          # workspace manifest
                  ├── ARCHITECTURE.md     # mandatory, explains crate graph
                  ├── crates/
                  │   ├── domain/         # no external dependencies except std
                  │   ├── application/    # depends on domain
                  │   ├── infrastructure/ # depends on domain, application
                  │   ├── api-types/      # shared data transfer types
                  │   └── cli/            # binary crate, depends on all
                  └── tests/
                      └── integration/    # integration tests, depends on infrastructure
                  ```

                  **Workspace Cargo.toml mandatory sections:**
                  ```toml
                  [workspace]
                  members = ["crates/*"]
                  resolver = "2"

                  [workspace.dependencies]
                  # All third-party dependencies are declared here with pinned versions.
                  # Member crates inherit: serde = { workspace = true }
                  tokio = { version = "1", features = ["full"] }
                  serde = { version = "1", features = ["derive"] }
                  thiserror = "2"
                  anyhow = "1"
                  tracing = "0.1"

                  [workspace.package]
                  edition = "2021"
                  rust-version = "1.82"
                  license = "MIT OR Apache-2.0"
                  authors = ["Author Name <email@example.com>"]
                  ```

                  **Rules:**
                  - All version numbers live in `[workspace.dependencies]`. Member crates inherit with `{ workspace = true }`. Never specify a version in a member crate's `Cargo.toml`.
                  - The `domain` crate depends only on `std` and possibly `serde` (for serialization of domain types). No I/O crates, no HTTP clients, no database drivers.
                  - Feature flags must be documented. Every non-default feature has a comment explaining what it enables and when to use it.
                  - `dev-dependencies` for test utilities are workspace-inherited when shared across crates.
                  - `[profile.release]` settings: `lto = "thin"`, `codegen-units = 1`, `panic = "abort"`.
                  - `[profile.bench]` inherits from release.
                  - Never use `path` dependencies pointing outside the workspace root. They indicate the workspace is improperly bounded.
                  - `Cargo.lock` is committed for binary crates and applications. It is not committed for pure library crates.

                  ---

                  ## Dependency Management Rules

                  Every dependency is a liability. Every dependency is someone else's code you must audit, update, and trust. Minimize the dependency graph.

                  **Before adding a dependency, ask:**
                  1. Does `std` already provide this? `HashMap`, `BTreeMap`, sorting, parsing integers, `Display`, string formatting — all in `std`.
                  2. Is there a single-file implementation that fits in the codebase? A 50-line helper function costs less than a crate.
                  3. Does the crate have an active maintainer? Check the last commit date and open issues.
                  4. What does it transitively pull in? Run `cargo tree` before adding a dependency.

                  **Approved dependency tiers:**
                  - Tier 1 (always acceptable): `serde`, `tokio`, `tracing`, `thiserror`, `anyhow`, `chrono`, `uuid`, `rand`, `regex`, `itertools`, `bytes`.
                  - Tier 2 (acceptable with justification): `reqwest`, `sqlx`, `axum`, `tonic`, `clap`, `rayon`, `crossbeam`, `flume`, `parking_lot`.
                  - Tier 3 (requires explicit review): anything with `unsafe` in its own code, anything pulling in C FFI, anything with >50 transitive dependencies.

                  **Version pinning:**
                  - Use tilde requirements for minor versions: `~1.5` pins to `1.5.x`.
                  - Use caret requirements for compatible versions: `^1` allows `1.x.y`.
                  - Never use `*` as a version. Never use `>=` without an upper bound.
                  - After `cargo update`, run the full test suite before committing the updated `Cargo.lock`.

                  **Feature hygiene:**
                  - Enable only the features you use. `tokio = { version = "1", features = ["rt-multi-thread", "macros", "sync", "time"] }` — not `features = ["full"]` in library crates.
                  - `default-features = false` when you need only a subset of a crate's functionality.

                  ---

                  ## Naming Deep Rules — Every Name Is a Contract

                  Names are the most durable part of an API. A bad name outlives the code that uses it. Apply these rules with the understanding that the name is a commitment.

                  **Getters:**
                  - A getter that returns a reference: `fn name(&self) -> &str` — named after the field, no `get_` prefix.
                  - A getter that copies a value: `fn count(&self) -> usize` — same, no `get_`.
                  - `get_` prefix is reserved for methods that can fail and return `Option<&T>` or `Option<T>`. `HashMap::get` is the canonical example.
                  - Infallible owned value: `fn into_name(self) -> String`.
                  - `get_` for `Option` returns, never for infallible returns. This is the standard library convention.

                  **Conversion method names:**
                  - `as_foo()`: cheap reference-to-reference conversion. `as_str()`, `as_bytes()`. Returns a borrowed type.
                  - `to_foo()`: expensive conversion that allocates. `to_string()`, `to_owned()`, `to_vec()`. Returns an owned type.
                  - `into_foo()`: consumes self. `into_bytes()`, `into_inner()`. Returns an owned type.
                  - These conventions are followed by the entire standard library and must be followed in all crates.

                  **Boolean naming:**
                  - Boolean getters use `is_` or `has_` or `can_` prefix: `is_empty()`, `has_children()`, `can_send()`.
                  - Never name a boolean `flag`, `check`, `ok`, `status`, `result`. These names reveal nothing.
                  - A boolean struct field: `is_enabled`, `has_error`, `can_retry`.

                  **Iterator methods:**
                  - `iter()`: returns an iterator over `&T`.
                  - `iter_mut()`: returns an iterator over `&mut T`.
                  - `into_iter()`: consumes self, returns an iterator over `T`.
                  - All three are implemented via `IntoIterator` for the collection type and its references.

                  **Error variant naming:**
                  - Error variants are named for the condition, not the action: `NotFound`, `InvalidInput`, `Unauthorized`. Not `GetFailed`, `ParseError`, `CheckFailed`.
                  - When the error carries context, the context fields are named for the thing being described: `InvalidInput { field: String, reason: String }`. Not `message`, not `description`, not `data`.

                  **Lifetime names:**
                  - `'a`, `'b` are acceptable only when the lifetime is anonymous and has no semantic meaning.
                  - Named lifetimes for function signatures: `'input`, `'buffer`, `'arena`, `'request`. Names that say what the lifetime is tied to.
                  - `'static` is the entire program lifetime. When you write `'static`, you mean this value will never be dropped. Be certain.
                  - `'de` is the conventional name for the deserializer lifetime in serde implementations.

                  ---

                  ## Trait Implementation Is Not Optional

                  Every type must implement the full set of traits its nature demands. LLMs skip trait implementations. This is forbidden.

                  **Types that hold a value of a printable type implement `Display`:**
                  If the type wraps a `String`, `u64`, or any primitive, it implements `Display`. No exceptions. `Display` is how users see the value. Without it, the type is incomplete.

                  **Types that are compared implement all comparison traits:**
                  If a type implements `PartialEq`, it must implement `Eq` when equality is total. If it implements `Eq` and `PartialOrd`, it must implement `Ord`. The four traits come as a group.

                  **Types used in hash maps implement both `Hash` and `Eq`:**
                  If you derive `Hash`, you must also derive `Eq`. They are a pair. The invariant: values that are `Eq` must have the same `Hash`.

                  **Domain types implement `From` for their raw inputs:**
                  ```rust
                  // If User has an id, and the id is a UUID in the database:
                  impl From<uuid::Uuid> for UserId {
                      fn from(uuid: uuid::Uuid) -> Self {
                          Self { uuid }
                      }
                  }
                  ```

                  **Types that may fail to construct implement `TryFrom`:**
                  Not a custom `parse()` method. Not `from_str_unchecked()`. `TryFrom<String>` or `TryFrom<&str>`. The standard library uses `TryFrom`. User code must too.

                  **Types that have a meaningful default implement `Default`:**
                  Configuration structs, builders, empty collections — they all implement `Default`. The default is the safe, zero-initialized, ready-to-configure state.

                  **Types that can be serialized for storage or transport implement `Serialize` and `Deserialize`:**
                  These come in a pair. A type that is `Serialize` but not `Deserialize` is usually wrong. The exception is types whose deserialization requires validation — those use `#[serde(try_from = "RawType")]`.

                  **Standard library trait checklist for every new type:**
                  - `Debug`: always, via derive.
                  - `Clone`: when the type has no unique ownership semantics.
                  - `Copy`: when `Clone` is trivial (no heap allocation in the type or any field).
                  - `PartialEq`, `Eq`: when equality comparisons are meaningful.
                  - `PartialOrd`, `Ord`: when ordering is meaningful and total.
                  - `Hash`: when the type will be used in hash maps or sets.
                  - `Display`: when the type has a human-readable representation.
                  - `FromStr`: when the type can be constructed from a string (for CLI, config parsing).
                  - `Default`: when there is a sensible zero-value.
                  - `From<T>` / `Into<T>`: for all natural, infallible conversions.
                  - `TryFrom<T>` / `TryInto<T>`: for all fallible conversions.
                  - `Serialize` / `Deserialize`: for all types crossing serialization boundaries.
                  - `Error`: for all error types.
                  - `IntoIterator`: for all collection types.
                  - `Index` / `IndexMut`: for collections that support indexed access.

                  When you skip any of these, you have a reason. State it in a comment. If you cannot state a reason, implement the trait.

                  ---

                  ## Impl Block Organization — Every impl Has a Structure

                  Every `impl` block follows the same internal ordering. This is not a preference. It is a rule.

                  **Order within a single `impl SelfType` block:**
                  1. `pub fn new(...)` — constructor(s).
                  2. `pub fn from_*(...)` — named constructors (alternatives to `new`).
                  3. `pub fn is_*(&self) -> bool` — predicate methods.
                  4. `pub fn *(&self) -> &T` — immutable getter methods.
                  5. `pub fn *_mut(&mut self) -> &mut T` — mutable getter methods.
                  6. `pub fn with_*(mut self, ...) -> Self` — builder-style setters.
                  7. `pub fn set_*(...)` — mutation methods.
                  8. `pub fn into_*(self) -> T` — consuming conversion methods.
                  9. `pub fn *(...)` — other public methods.
                  10. `fn *(...)` — private methods.

                  **Separate impl blocks for trait implementations:**
                  Each trait implementation is its own `impl` block, never merged into the main `impl` block. Order of trait impl blocks:
                  1. `impl Default`
                  2. `impl Display`
                  3. `impl Debug` (if custom, not derived)
                  4. `impl From<T>` / `impl TryFrom<T>` — one block per source type
                  5. `impl Error`
                  6. `impl Iterator` / `impl IntoIterator`
                  7. `impl Index` / `impl IndexMut`
                  8. All other trait implementations, alphabetical by trait name

                  **Derive placement:**
                  Derive macros appear directly above `struct` or `enum` declarations, in this order:
                  1. Standard library derives: `Clone, Copy, Debug, Default, Eq, Hash, Ord, PartialEq, PartialOrd`
                  2. External derives: `Deserialize, Serialize` (serde), `Error` (thiserror), `Arbitrary` (proptest), etc.

                  Always alphabetical within each group. Consistent ordering prevents diff noise.

                  ---

                  ## Serde Deep Reference

                  Serialization and deserialization are system boundaries. Apply the same rigor as parse-don't-validate.

                  **Never serialize domain types directly:**
                  Domain types may change freely. Wire types must remain stable. Define separate wire types:
                  ```rust
                  // Domain type — internal representation, free to evolve.
                  struct User {
                      identifier: UserId,
                      email_address: EmailAddress,
                      account_created: DateTime<Utc>,
                  }

                  // Wire type — stable, versioned, annotated for serde.
                  #[derive(Serialize, Deserialize)]
                  struct UserDto {
                      id: String,
                      email: String,
                      created_at: String,
                  }

                  impl From<User> for UserDto {
                      fn from(user: User) -> Self {
                          Self {
                              id: user.identifier.to_string(),
                              email: user.email_address.to_string(),
                              created_at: user.account_created.to_rfc3339(),
                          }
                      }
                  }
                  ```

                  **Field renaming:**
                  - Use `#[serde(rename_all = "camelCase")]` at the container level to match JSON conventions.
                  - Use `#[serde(rename = "specific_name")]` at the field level for exceptions.
                  - Never rely on Rust field names matching the wire format by accident — always explicit.

                  **Versioning:**
                  When a wire type changes, use `#[serde(default)]` for new optional fields and `#[serde(deny_unknown_fields)]` during a transition period. Never remove a field from a `Deserialize` type without a versioning strategy.

                  **Validation during deserialization:**
                  Use `#[serde(try_from = "RawType")]` to run validation during deserialization:
                  ```rust
                  #[derive(Deserialize)]
                  #[serde(try_from = "String")]
                  struct EmailAddress(String);

                  impl TryFrom<String> for EmailAddress {
                      type Error = InvalidEmailError;
                      fn try_from(raw: String) -> Result<Self, Self::Error> {
                          validate_email(&raw)?;
                          Ok(Self(raw))
                      }
                  }
                  ```

                  **Rules:**
                  - `#[serde(deny_unknown_fields)]` on all inbound types (from external systems). Unknown fields from a trusted source indicate version mismatch — fail loudly.
                  - `#[serde(skip_serializing_if = "Option::is_none")]` for optional fields in outbound types.
                  - Never use `serde_json::Value` in domain code. Parse JSON into typed structs immediately.
                  - `serde_json::to_string_pretty` is for debugging and human-readable output only. Production serialization uses `serde_json::to_string` or a binary format.

                  ---

                  ## Error Handling Deep Rules

                  **The fundamental split:**
                  - Library crates: use `thiserror`. Define precise, enumerated error types. Every error variant carries exactly the context needed to diagnose it — nothing more.
                  - Application crates: use `anyhow`. Wrap library errors into application context with `.context("while loading user config")`.
                  - Never use `anyhow` in a library. Library consumers cannot pattern-match on `anyhow::Error` to handle specific cases.
                  - Never use `thiserror` as a catch-all in an application where `anyhow` would be cleaner.

                  **thiserror error design:**
                  ```rust
                  #[derive(Debug, thiserror::Error)]
                  enum DatabaseError {
                      #[error("connection failed: {reason}")]
                      ConnectionFailed { reason: String },

                      #[error("record not found: {entity} with id {id}")]
                      NotFound { entity: String, id: String },

                      #[error("query failed")]
                      QueryFailed(#[from] sqlx::Error),
                  }
                  ```

                  **Error variant rules:**
                  - Every variant carries enough context to produce a helpful error message without looking at the source code.
                  - `#[from]` wraps the underlying error. This is the only acceptable use of wrapping — do not hand-write `impl From<sqlx::Error> for DatabaseError` when `#[from]` does it.
                  - `#[source]` (without `#[from]`) exposes the underlying error for programmatic inspection without converting from it automatically.
                  - Error types implement `Send + Sync + 'static` — use `static_assertions::assert_impl_all!` to verify this.

                  **The `?` operator:**
                  - Use `?` on every fallible call. Never `unwrap()` or `expect()` in production code paths.
                  - `expect()` is acceptable in tests and in main program initialization where panicking is the correct behavior.
                  - When `?` converts between error types, the conversion must be explicit or via `#[from]`. Never `.map_err(|_| SomeError)` that discards information.
                  - `.map_err(|e| Error::Foo { reason: e.to_string() })` — acceptable when wrapping context.

                  **Error propagation across async:**
                  - Errors returned from `tokio::spawn` arrive as `JoinError`. Inspect and unwrap the inner error explicitly.
                  - Never box errors as `Box<dyn Error>` in async function signatures. Use `anyhow::Error` or a concrete type.

                  ---

                  ## Testing Deep Rules

                  **Test structure — every test follows AAA:**
                  Every test has three clearly delineated phases: Arrange, Act, Assert. Name helper functions with the phase they belong to.

                  ```rust
                  #[test]
                  fn user_rejects_underage_applicant() {
                      // Arrange
                      let age = Age::try_from(17).expect("17 is a valid u32 for Age construction attempt");

                      // Act
                      let result = age;

                      // Assert
                      assert!(result.is_err());
                      assert!(matches!(result, Err(InvalidAgeError::BelowMinimum { .. })));
                  }
                  ```

                  **Test naming:**
                  - Test function names are full sentences describing the behavior being tested.
                  - Format: `{subject}_{condition}_{expected_outcome}`. `user_with_invalid_email_rejects_construction`. `empty_cart_total_is_zero`. `concurrent_writes_to_different_keys_do_not_conflict`.
                  - No `test_` prefix. The `#[test]` attribute is sufficient.

                  **Test isolation:**
                  - Tests must not share state. No global mutable state, no shared files, no shared network ports.
                  - Database tests use transactions that are rolled back at test end. Never commit test data.
                  - Tests that need time should control time via dependency injection or `tokio::time::pause`.

                  **What to test:**
                  - The public API of every public type.
                  - Every error path: what error is returned when each invariant is violated.
                  - Boundary conditions: minimum and maximum values, empty inputs, single-element inputs.
                  - Concurrency: tests that spawn multiple tasks and verify the result under concurrent access.
                  - Integration tests for database access, HTTP clients, file I/O — these live in `tests/`.

                  **Test helpers:**
                  - Builder pattern for test fixtures: `UserBuilder::new().with_email("test@test.com").build()`.
                  - Shared test builders live in `tests/common/mod.rs` or a `test_support` crate.
                  - Never inline complex setup in a test body. Extract to a named function.

                  ---

                  ## Documentation Deep Rules

                  **Module-level documentation is mandatory:**
                  Every module has a `//!` doc comment at the top of `mod.rs`. It states:
                  - What the module does.
                  - What the main types are.
                  - A one-line usage example if non-obvious.
                  Length: 3-10 lines. Never longer unless the module is complex.

                  **Public item documentation:**
                  - Every `pub` struct, `pub` enum, `pub` trait, and `pub fn` has a doc comment.
                  - The first sentence is the summary — one line, no period at the end.
                  - Subsequent paragraphs provide detail, examples, panics, errors, safety.
                  - `# Errors` section: every function returning `Result` documents the error conditions.
                  - `# Panics` section: every function that can panic documents when and why.
                  - `# Safety` section: every `unsafe fn` documents the preconditions.

                  **Doc tests:**
                  Code examples in documentation are compiled and run with `cargo test --doc`. Write them. Broken examples are worse than no examples.

                  **Intra-doc links:**
                  Link to related types and methods using `[TypeName]` and `[method_name]`. Avoid spelling out full paths when a relative link works.

                  **What must NOT be in documentation:**
                  - The date, author, or version the item was introduced — that belongs in the changelog.
                  - Explanations of why a past version was different — the code is the current state.
                  - Internal implementation details for public items — describe behavior, not implementation.

                  ---

                  ## Performance Patterns — Write for the CPU

                  Performance is a feature. Write code that the CPU can execute efficiently. Measure first, optimize second — but write obviously efficient code on the first pass.

                  **Allocation budget:**
                  - Profile allocations in hot paths with `cargo-flamegraph` or `dhat`.
                  - A function called once is not a hot path. A function called per request or per message or per frame is.
                  - Pre-allocate with `Vec::with_capacity` when the size is known or estimable.
                  - Prefer stack allocation over heap allocation for small, fixed-size data.

                  **Cache locality:**
                  - Data accessed together should live together. Use structs of arrays (SoA) instead of arrays of structs (AoS) for data processed in bulk.
                  - Avoid pointer-chasing in hot loops: `Vec<Box<T>>` is worse than `Vec<T>`. Prefer arena allocation when ownership allows.

                  **SIMD-friendly code:**
                  - Process data in batches rather than element-by-element in tight loops.
                  - Use `chunks_exact` for guaranteed chunk sizes the compiler can vectorize.
                  - Annotate performance-critical functions with `#[inline]` when cross-crate inlining matters.

                  **String formatting is expensive:**
                  - Never call `format!` to build a string that is immediately written to an output. Use `write!` to write directly.
                  - Never use `String::new()` followed by `+` for concatenation. Use `format!` or a `String::with_capacity` and `push_str` loop.
                  - `to_string()` allocates. In hot paths, write to a pre-allocated buffer instead.

                  **Cloning is expensive:**
                  - Profile before cloning in hot paths. An `.Arc<T>` clone is cheap. A `Vec<T>` clone is not.
                  - `Rc::clone` and `Arc::clone` must be written as `Rc::clone(&value)`, not `value.clone()`, to make the cheap reference-count bump visible and distinguish it from deep clones.

                  ---

                  ## The Complexity Budget

                  Every codebase has a complexity budget. Spend it on the problem, not the infrastructure. Measure every abstraction against its cost.

                  **Abstraction cost:**
                  - An abstraction is only worth its weight when it is used in at least three places with genuinely different implementations.
                  - A trait with one implementation is probably not a trait — it is a struct.
                  - A module with one function is probably not a module — it is a function in the parent module.
                  - A wrapper type with no behavior added over the wrapped type is unnecessary — remove it.

                  **Generic cost:**
                  - Generics monomorphize. Every instantiation is compiled separately. Use `dyn Trait` when the runtime cost is acceptable and the binary size matters more than the virtual dispatch overhead.
                  - `impl Trait` in function position is syntactic sugar for a generic. It monomorphizes. Use `Box<dyn Trait>` for heterogeneous collections.
                  - Type parameters that appear only in `PhantomData` are free at runtime.

                  **Lifetime cost:**
                  - Lifetimes are zero-cost at runtime. They are compile-time annotations. Add them when they express a real relationship. Remove them when they add noise without expressing anything.
                  - Lifetime elision rules: when a function has one reference input, the output lifetimes can be elided. Write them explicitly when elision makes the relationship unclear.

                  ---

                  ## Never add a turbofish that the compiler would infer correctly without it.

                  ---

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
              ".config/claude/settings.json" = {
                source = jsonFormat.generate "claude-code-settings.json" {
                  "$schema" = "https://json.schemastore.org/claude-code-settings.json";
                  skipDangerousModePermissionPrompt = true;
                  effortLevel = "high";
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
