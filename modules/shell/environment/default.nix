{
  pkgs,
  lib,
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
      systemPackages = [
        pkgs.neovim
        self.packages.${system}.copyro
      ];
    };
    systemd = {
      services = {
        copy-nix-config = {
          description = "Copy read-only reference to flake into a writable path to allow changing configuration";
          serviceConfig = {
            Type = "oneshot";
            wantedBy = ["multi-user.target"];
            ExecStart = "${lib.getExe self.packages.${system}.copyro} /etc/flake /home/${config.modules.users.user}/.local/src/cymenix";
          };
        };
      };
    };
  };
}
