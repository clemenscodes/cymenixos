{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules;
  isDesktop = osConfig.modules.display.gui != "headless";
in {
  imports = [
    (import ./chromium {inherit inputs pkgs lib;})
    (import ./firefox {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      browser = {
        enable = lib.mkEnableOption "Enables a cool browser" // {default = false;};
        defaultBrowser = lib.mkOption {
          type = lib.types.str;
          default =
            if isDesktop
            then "firefox"
            else "echo";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.browser.enable) {
    home = {
      sessionVariables = {
        BROWSER = cfg.browser.defaultBrowser;
      };
    };
  };
}
