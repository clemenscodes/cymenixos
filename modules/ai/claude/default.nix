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
