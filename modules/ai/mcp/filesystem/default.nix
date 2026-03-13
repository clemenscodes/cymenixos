{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  filesystem-mcp = pkgs.callPackage ./package.nix {};
  inherit (config.modules.users) user;
in {
  options.modules.ai.mcp.filesystem.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Filesystem MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.filesystem.enable) {
    modules.ai.mcp.servers.filesystem = {
      command = "${filesystem-mcp}/bin/mcp-server-filesystem";
      args = ["/home/${user}/.local/src"];
    };
  };
}
