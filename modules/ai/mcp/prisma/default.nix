{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  prisma-mcp = pkgs.callPackage ./package.nix {prisma = pkgs.prisma;};
in {
  options.modules.ai.mcp.prisma.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Prisma MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.prisma.enable) {
    modules.ai.mcp.servers.prisma = {
      command = "${prisma-mcp}/bin/prisma-mcp";
    };
  };
}
