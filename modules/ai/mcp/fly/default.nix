{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.fly.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Fly.io MCP server (flyctl mcp server)";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.fly.enable) {
    modules.ai.mcp.servers."fly.io" = {
      command = "${pkgs.flyctl}/bin/flyctl";
      args = ["mcp" "server"];
      env = {
        FLY_API_TOKEN = ''''${FLY_API_TOKEN}'';
      };
    };
  };
}
