{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.markitdown.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable MarkItDown MCP server (Microsoft - converts PDF, Word, Excel, etc. to Markdown)";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.markitdown.enable) {
    modules.ai.mcp.servers.markitdown = {
      command = "${pkgs.markitdown-mcp}/bin/markitdown-mcp";
    };
  };
}
