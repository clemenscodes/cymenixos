{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  neon-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.neon.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Neon MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.neon.enable) {
    modules.ai.mcp.servers.neon = {
      command = "${neon-mcp}/bin/mcp-server-neon";
      args = ["start" ''''${NEON_API_KEY}''];
      env = {
        NEON_API_KEY = ''''${NEON_API_KEY}'';
      };
    };
  };
}
