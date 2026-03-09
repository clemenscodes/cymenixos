{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  git-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.git.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Git MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.git.enable) {
    modules.ai.mcp.servers.git = {
      command = "${git-mcp}/bin/git-mcp-server";
    };
  };
}
