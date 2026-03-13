{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  time-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.time.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Time MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.time.enable) {
    modules.ai.mcp.servers.time = {
      command = "${time-mcp}/bin/mcp-server-time";
    };
  };
}
