{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  redis-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.redis.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Redis MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.redis.enable) {
    modules.ai.mcp.servers.redis = {
      command = "${redis-mcp}/bin/mcp-server-redis";
      env = {
        REDIS_URL = ''''${REDIS_URL}'';
      };
    };
  };
}
