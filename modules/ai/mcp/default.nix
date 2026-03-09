{
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./atlassian {inherit lib;})
    (import ./azure-devops {inherit pkgs lib;})
    (import ./context7 {inherit pkgs lib;})
    (import ./docker {inherit pkgs lib;})
    (import ./filesystem {inherit pkgs lib;})
    (import ./git {inherit pkgs lib;})
    (import ./github {inherit pkgs lib;})
    (import ./grafana {inherit pkgs lib;})
    (import ./kubernetes {inherit pkgs lib;})
    (import ./memory {inherit pkgs lib;})
    (import ./mongodb {inherit pkgs lib;})
    (import ./neon {inherit pkgs lib;})
    (import ./nixos {inherit pkgs lib;})
    (import ./nx {inherit pkgs lib;})
    (import ./playwright {inherit pkgs lib;})
    (import ./postgres {inherit pkgs lib;})
    (import ./prisma {inherit pkgs lib;})
    (import ./redis {inherit pkgs lib;})
    (import ./sequential-thinking {inherit pkgs lib;})
    (import ./terraform {inherit pkgs lib;})
    (import ./time {inherit pkgs lib;})
  ];
  options.modules.ai.mcp = {
    enable = lib.mkEnableOption "Enable MCP server integration";
    servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      internal = true;
      description = "Assembled MCP server configurations based on enabled servers";
    };
  };
}
