{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  mongodb-mcp = pkgs.callPackage ./package.nix {};
  cfg = config.modules.ai.mcp.mongodb;
in {
  options.modules.ai.mcp.mongodb = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable MongoDB MCP server";
    };
    connectionString = lib.mkOption {
      type = lib.types.str;
      default = "mongodb://localhost:27017/?directConnection=true";
      description = "MongoDB connection string URI";
    };
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && cfg.enable) {
    modules.ai.mcp.servers.mongodb = {
      command = "${mongodb-mcp}/bin/mongodb-mcp-server";
      env = {
        MDB_MCP_CONNECTION_STRING = cfg.connectionString;
      };
    };
  };
}
