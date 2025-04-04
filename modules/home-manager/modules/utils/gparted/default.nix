{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  options = {
    modules = {
      utils = {
        gparted = {
          enable = lib.mkEnableOption "Enable GParted" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf cfg.utils.gparted.enable {
    xdg = {
      desktopEntries = {
        gparted = {
          name = "GParted";
          genericName = "Partition Editor";
          comment = "Create, reorganise, and delete partitions";
          type = "Application";
          exec = "sudo -E ${pkgs.gparted}/bin/gparted %f";
          terminal = false;
          icon = "${pkgs.gparted}/share/icons/hicolor/scalable/apps/gparted.svg";
          categories = ["GTK" "GNOME" "System" "Filesystem"];
          startupNotify = true;
        };
      };
    };
  };
}
