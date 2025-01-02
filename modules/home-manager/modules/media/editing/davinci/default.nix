{
  inputs,
  lib,
  ...
}: {
  system,
  config,
  ...
}: let
  cfg = config.modules.media.editing;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
in {
  options = {
    modules = {
      media = {
        editing = {
          davinci = {
            enable = lib.mkEnableOption "Enable DaVinci Resolve" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.davinci.enable) {
    home = {
      packages = [pkgs.davinci-resolve];
    };
    xdg = {
      desktopEntries = {
        resolve = {
          name = "Davinci Resolve";
          genericName = "Video Editor";
          exec = "env QT_QPA_PLATFORM=xcb ${pkgs.davinci-resolve}/bin/davinci-resolve %u";
          icon = "DV_Resolve";
          terminal = false;
          type = "Application";
          categories = ["AudioVideo"];
          mimeType = ["application/x-resolveproj"];
        };
      };
    };
  };
}
