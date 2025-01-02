{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.shell;
in {
  options = {
    modules = {
      shell = {
        nom = {
          enable = lib.mkEnableOption "Enable the nix output monitor" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nom.enable) {
    home = {
      packages = [pkgs.nix-output-monitor];
    };
  };
}
