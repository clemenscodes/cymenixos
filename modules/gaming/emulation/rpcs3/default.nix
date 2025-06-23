{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming.emulation;
  ps3bios = import ./firmware {inherit pkgs;};
in {
  options = {
    modules = {
      gaming = {
        emulation = {
          rpcs3 = {
            enable = lib.mkEnableOption "Enable rpcs3 emulation (PlayStation 3)" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.rpcs3.enable) {
    networking = {
      firewall = {
        allowedTCPPorts = [5000];
        allowedUDPPorts = [1900 3658];
      };
    };
    services = {
      miniupnpd = {
        enable = true;
        upnp = true;
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${config.modules.users.user} = {
          home = {
            packages = [
              pkgs.rpcs3
              pkgs.rusty-psn-gui
            ];
            file = {
              ".config/rpcs3/bios" = {
                source = "${ps3bios}/bios";
              };
            };
            persistence = lib.mkIf config.modules.boot.enable {
              "${config.modules.boot.impermanence.persistPath}/home/${config.modules.users.user}" = {
                directories = [".config/rpcs3"];
              };
            };
          };
        };
      };
    };
  };
}
