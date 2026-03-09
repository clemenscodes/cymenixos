{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options.modules.ai.mcp.terraform.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable Terraform MCP server";
  };
  config = lib.mkIf (config.modules.ai.enable && config.modules.ai.mcp.enable && config.modules.ai.mcp.terraform.enable) {
    modules.ai.mcp.servers.terraform = {
      command = "${pkgs.terraform-mcp-server}/bin/terraform-mcp-server";
    };
  };
}
