{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) name;
in {
  options = {
    modules = {
      gaming = {
        umu = {
          enable = lib.mkEnableOption "Enable umu" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.umu.enable) {
    environment = {
      systemPackages = [
        (inputs.umu.packages.${system}.default.override {
          extraPkgs = pkgs: [];
          extraLibraries = pkgs: [];
          withMultiArch = true;
          withTruststore = true;
          withDeltaUpdates = true;
        })
      ];
      persistence = {
        ${persistPath} = {
          users = {
            ${name} = {
              directories = [
                ".cache/umu"
                ".local/share/umu"
              ];
            };
          };
        };
      };
    };
  };
}
