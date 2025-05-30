{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation;
  inherit (config.modules.users) user;
in {
  options = {
    modules = {
      virtualisation = {
        podman = {
          enable = lib.mkEnableOption "Enable podman" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.podman.enable) {
    environment = {
      systemPackages = [
        pkgs.dive
        pkgs.podman-tui
        pkgs.docker-compose
      ];
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = [];
        };
      };
    };
    virtualisation = {
      podman = {
        inherit (cfg.podman) enable;
        dockerCompat = cfg.docker.enable;
        defaultNetwork = {
          settings = {
            dns_enabled = true;
          };
        };
      };
    };
  };
}
