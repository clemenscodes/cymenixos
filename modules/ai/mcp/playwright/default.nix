{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.playwright.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Playwright MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.playwright.enable) {
    modules.ai.mcp.servers.playwright = {
      command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
    };
  };
}
