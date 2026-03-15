{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
in {
  options = {
    modules = {
      gaming = {
        gamescope = {
          enable = lib.mkEnableOption "Enable gamescope" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gamescope.enable) {
    environment = {
      systemPackages = with pkgs; [gamescope-wsi];
    };
    programs = {
      gamescope = {
        inherit (cfg.gamescope) enable;
        package = pkgs.gamescope;
        capSysNice = true;
      };
    };
  };
}
