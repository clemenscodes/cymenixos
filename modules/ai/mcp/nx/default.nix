{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  nx-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.nx.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Nx MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.nx.enable) {
    modules.ai.mcp.servers.nx = {
      command = "${nx-mcp}/bin/nx-mcp";
    };
  };
}
