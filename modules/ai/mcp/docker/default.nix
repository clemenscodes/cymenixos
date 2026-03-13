{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  docker-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.docker.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Docker MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.docker.enable) {
    modules.ai.mcp.servers.docker = {
      command = "${docker-mcp}/bin/mcp-server-docker";
    };
  };
}
