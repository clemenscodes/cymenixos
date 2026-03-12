{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  chrome-devtools-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.chrome-devtools.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Chrome DevTools MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.chrome-devtools.enable) {
    modules.ai.mcp.servers.chrome-devtools = {
      command = "${chrome-devtools-mcp}/bin/chrome-devtools-mcp";
    };
  };
}
