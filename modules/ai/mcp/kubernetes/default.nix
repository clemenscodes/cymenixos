{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.kubernetes.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Kubernetes MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.kubernetes.enable) {
    modules.ai.mcp.servers.kubernetes = {
      command = "${pkgs.mcp-k8s-go}/bin/mcp-k8s-go";
    };
  };
}
