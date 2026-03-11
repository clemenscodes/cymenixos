{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  sequential-thinking-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp."sequential-thinking".enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Sequential Thinking MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp."sequential-thinking".enable) {
    modules.ai.mcp.servers.sequential-thinking = {
      command = "${sequential-thinking-mcp}/bin/mcp-server-sequential-thinking";
    };
  };
}
