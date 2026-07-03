{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  browsers = pkgs.playwright-driver.browsers;
  # On NixOS the bundled browsers live in a read-only store path, and
  # playwright-mcp 0.0.69 (a) defaults the chromium channel to
  # "chrome-for-testing" (absent from the Nix bundle) and (b) creates its
  # browser profile under PLAYWRIGHT_BROWSERS_PATH itself. Both fail in the
  # store. This wrapper pins the bundled chromium binary and redirects the
  # profile/output dirs to a writable cache location.
  wrapper = pkgs.writeShellScriptBin "playwright-mcp" ''
    set -euo pipefail
    profile="$HOME/.cache/playwright-mcp/profile"
    output="$HOME/.cache/playwright-mcp/output"
    mkdir -p "$profile" "$output"
    chrome=( ${browsers}/chromium-*/chrome-linux64/chrome )
    exec ${pkgs.playwright-mcp}/bin/playwright-mcp \
      --browser chromium \
      --executable-path "''${chrome[0]}" \
      --user-data-dir "$profile" \
      --output-dir "$output" \
      "$@"
  '';
in {
  options.modules.ai.mcp.playwright.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Playwright MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.playwright.enable) {
    modules.ai.mcp.servers.playwright = {
      command = "${wrapper}/bin/playwright-mcp --isolated";
    };
  };
}
