{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  context7-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.context7.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Context7 MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.context7.enable) {
    modules.ai.mcp.servers.context7 = {
      command = "${context7-mcp}/bin/context7-mcp";
    };
  };
}
