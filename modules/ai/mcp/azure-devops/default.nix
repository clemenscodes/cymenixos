{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  azure-devops-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp."azure-devops".enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Azure DevOps MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp."azure-devops".enable) {
    modules.ai.mcp.servers.azure-devops = {
      command = "${azure-devops-mcp}/bin/mcp-server-azuredevops";
      args = ["--authentication" "envvar"];
      env = {
        ADO_MCP_AUTH_TOKEN = ''''${AZURE_DEVOPS_EXT_PAT}'';
      };
    };
  };
}
