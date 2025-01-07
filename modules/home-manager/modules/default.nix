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
    (import ./media {inherit inputs pkgs lib;})
    (import ./monitoring {inherit inputs pkgs lib;})
    (import ./networking {inherit inputs pkgs lib;})
    (import ./operations {inherit inputs pkgs lib;})
    (import ./organization {inherit inputs pkgs lib;})
    (import ./security {inherit inputs pkgs lib;})
    (import ./shell {inherit inputs pkgs lib;})
    (import ./storage {inherit inputs pkgs lib;})
    (import ./terminal {inherit inputs pkgs lib;})
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
        inherit (cfg) enable;
      };
    };
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}/${config.home.homeDirectory}" = {
          directories = [
            ".local/src"
            ".local/bin"
            ".local/share/keyrings"
            (lib.mkIf (osConfig.modules.gaming.enable && osConfig.modules.gaming.steam.enable) {
              directory = ".local/share/Steam";
              method = "symlink";
            })
          ];
        };
      };
      keyboard = {
        layout = osConfig.modules.locale.defaultLocale;
      };
      username = user;
      homeDirectory = "/home/${user}";
      sessionPath = ["${config.home.homeDirectory}/.local/bin"];
      activation = {
        rmUnusedNix = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
          rm -rf ${config.home.homeDirectory}/.nix-defexpr
          rm -rf ${config.home.homeDirectory}/.nix-profile
        '';
      };
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
