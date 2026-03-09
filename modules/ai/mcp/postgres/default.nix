{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  postgres-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.postgres.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable PostgreSQL MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.postgres.enable) {
    modules.ai.mcp.servers.postgres = {
      command = "${postgres-mcp}/bin/postgres-mcp";
      env = {
        DATABASE_URI = ''''${POSTGRES_CONNECTION_STRING}'';
      };
    };
  };
}
