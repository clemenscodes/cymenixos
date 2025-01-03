{
  pkgs,
  lib,
  cymenixos,
  ...
}: {
  self,
  config,
  system,
  ...
}: let
  cfg = config.modules.shell;
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
      systemPackages = [pkgs.neovim];
    };
    systemd = {
      user = {
        services = {
          copy-nix-config = {
            description = "Copy read-only reference to flake into a writable path to allow changing configuration";
            wantedBy = ["default.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${cymenixos.packages.${system}.default}/bin/copyro /etc/flake /home/${config.modules.users.user}/.local/src/cymenix";
            };
          };
        };
      };
    };
  };
}
