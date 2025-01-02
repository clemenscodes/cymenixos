{
  inputs,
  lib,
  ...
}: {
  config,
  osConfig,
  system,
  ...
}: let
  cfg = config.modules.media.communication;
  isDesktop = osConfig.modules.display.gui != "headless";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["discord"];
    };
  };
in {
  options = {
    modules = {
      media = {
        communication = {
          discord = {
            enable = lib.mkEnableOption "Enable discord" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.discord.enable && isDesktop) {
    home = {
      packages = [pkgs.discord];
    };
    xdg = {
      desktopEntries = {
        discord = {
          name = "Discord";
          type = "Application";
          categories = ["Network" "InstantMessaging"];
          exec = "discord --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WebRTCPipeWireCapturer";
          genericName = "All-in-one cross-platform voice and text chat for gamers";
          icon = "discord";
          mimeType = ["x-scheme-handler/discord"];
        };
      };
    };
  };
}
