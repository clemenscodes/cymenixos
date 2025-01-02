{
  inputs,
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules;
  osCfg = osConfig.modules.home-manager;
  user = osConfig.modules.users.user;
in {
  imports = [
    (import ./browser {inherit inputs pkgs lib;})
    (import ./development {inherit inputs pkgs lib;})
    (import ./display {inherit inputs pkgs lib;})
    (import ./editor {inherit inputs pkgs lib;})
    (import ./explorer {inherit inputs pkgs lib;})
    (import ./fonts {inherit inputs pkgs lib;})
    (import ./gaming {inherit inputs;})
    (import ./media {inherit inputs pkgs lib;})
    (import ./monitoring {inherit inputs pkgs lib;})
    (import ./networking {inherit inputs pkgs lib;})
    (import ./operations {inherit inputs pkgs lib;})
    (import ./organization {inherit inputs pkgs lib;})
    (import ./security {inherit inputs;})
    (import ./shell {inherit inputs pkgs lib;})
    (import ./storage {inherit inputs pkgs lib;})
    (import ./terminal {inherit pkgs;})
    (import ./utils {inherit inputs pkgs lib;})
    (import ./xdg {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      enable = lib.mkEnableOption "Enable home-manager modules" // {default = false;};
    };
  };
  config = lib.mkIf (cfg.enable && osCfg.enable) {
    programs = {
      home-manager = {
        enable = osCfg.enable && cfg.enable;
      };
    };
    home = {
      inherit (osConfig.system) stateVersion;
      keyboard = {
        layout = osConfig.modules.locale.defaultLocale;
      };
      username = user;
      homeDirectory = "/home/${user}";
      sessionPath = ["${config.home.homeDirectory}/.local/bin"];
      file = {
        ".local/src/README.md" = {
          text = ''
            # Source Code / Packages

            - This is the home for all external source code and projects
            - run `rr` to cd into this directory
          '';
        };
      };
    };
  };
}
