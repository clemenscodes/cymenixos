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
        nvd = {
          enable = lib.mkEnableOption "Enable nix version diffs" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nvd.enable) {
    home = {
      packages = [pkgs.nvd];
    };
  };
}
