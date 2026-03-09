{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  memory-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.memory.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Memory MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.memory.enable) {
    modules.ai.mcp.servers.memory = {
      command = "${memory-mcp}/bin/mcp-server-memory";
    };
  };
}
