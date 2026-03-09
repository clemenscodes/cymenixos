{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.nixos.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable NixOS MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.nixos.enable) {
    modules.ai.mcp.servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
  };
}
