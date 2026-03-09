{lib, ...}: {config, ...}: {
  options.modules.ai.mcp.atlassian.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Atlassian MCP server (Jira, Confluence, Compass)";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.atlassian.enable) {
    modules.ai.mcp.servers.atlassian = {
      type = "http";
      url = "https://mcp.atlassian.com/v1/mcp";
    };
  };
}
