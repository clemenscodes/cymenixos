{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.github.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable GitHub MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.github.enable) {
    modules.ai.mcp.servers.github = {
      command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
      args = ["stdio"];
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = ''''${GH_TOKEN}'';
      };
    };
  };
}
