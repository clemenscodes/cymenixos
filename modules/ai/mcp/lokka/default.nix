{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  lokka-mcp = pkgs.callPackage ./package.nix {};
in {
  options.modules.ai.mcp.lokka.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Lokka MCP server for Microsoft 365 (Graph API, Teams, Exchange, SharePoint, Azure, Entra)";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.lokka.enable) {
    modules.ai.mcp.servers.lokka = {
      command = "${lokka-mcp}/bin/lokka-mcp-server";
      env = {
        # Optional: Azure AD app registration credentials for non-interactive auth.
        # If unset, Lokka falls back to browser-based interactive login.
        AZURE_CLIENT_ID = ''''${AZURE_CLIENT_ID}'';
        AZURE_CLIENT_SECRET = ''''${AZURE_CLIENT_SECRET}'';
        AZURE_TENANT_ID = ''''${AZURE_TENANT_ID}'';
      };
    };
  };
}
