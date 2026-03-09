{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.grafana.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Grafana MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.grafana.enable) {
    modules.ai.mcp.servers.grafana = {
      command = "${pkgs.mcp-grafana}/bin/mcp-grafana";
      env = {
        GRAFANA_URL = ''''${GRAFANA_URL}'';
        GRAFANA_API_KEY = ''''${GRAFANA_API_KEY}'';
      };
    };
  };
}
