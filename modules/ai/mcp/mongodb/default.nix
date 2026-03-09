{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  mongodb-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.mongodb.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable MongoDB MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.mongodb.enable) {
    modules.ai.mcp.servers.mongodb = {
      command = "${mongodb-mcp}/bin/mongodb-mcp-server";
      env = {
        MONGODB_URI = ''''${MONGODB_URI}'';
      };
    };
  };
}
