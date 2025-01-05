{
  pkgs,
  lib,
  ...
}: {
  self,
  config,
  ...
}: let
  cfg = config.modules.shell;
  inherit (config.modules.users) user flake;
in {
  options = {
    modules = {
      shell = {
        environment = {
          enable = lib.mkEnableOption "Enable basic environment settings" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.environment.enable) {
    environment = {
      etc = {
        flake = {
          source = self.outPath;
        };
      };
      localBinInPath = true;
      homeBinInPath = true;
      systemPackages = [
        pkgs.neovim
        pkgs.cymenixos-scripts
      ];
    };
    systemd = {
      user = {
        services = {
          copy-nix-config = {
            description = "Copy read-only reference to flake into a writable path to allow changing configuration";
            wantedBy = ["default.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.cymenixos-scripts}/bin/copyro /etc/flake /home/${user}/${flake}";
            };
          };
        };
      };
    };
  };
}
