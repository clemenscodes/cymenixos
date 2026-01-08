{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.security;
  sshPort = 22;
  inherit (config.modules.boot.impermanence) persistPath;
in {
  options = {
    modules = {
      security = {
        ssh = {
          enable = lib.mkEnableOption "Enable SSH" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ssh.enable) {
    systemd = lib.mkIf config.modules.boot.enable {
      user = {
        tmpfiles = {
          rules = ["d %h/.config/ssh 700 - - - -"];
        };
      };
    };
    fileSystems = lib.mkIf config.modules.boot.enable {
      "/etc/ssh" = {
        depends = [persistPath];
        neededForBoot = true;
        inherit (config.modules.disk) device;
      };
    };
    environment = {
      persistence = lib.mkIf config.modules.boot.enable {
        "${persistPath}" = {
          directories = [
            {
              directory = "/etc/ssh";
              mode = "0700";
            }
          ];
          users = {
            ${config.modules.users.user} = {
              directories = [
                {
                  directory = ".ssh";
                  mode = "0700";
                }
              ];
            };
          };
        };
      };
    };
    networking = {
      firewall = {
        allowedTCPPorts = [sshPort];
      };
    };
    services = {
      openssh = {
        inherit (cfg.ssh) enable;
        ports = [sshPort];
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
        # Known vulnerability. See
        # https://security.stackexchange.com/questions/110639/how-exploitable-is-the-recent-useroaming-ssh-vulnerability
        moduliFile = pkgs.runCommand "filterModuliFile" {} ''
          awk '$5 >= 3071' "${config.programs.ssh.package}/etc/ssh/moduli" >"$out"
        '';
        hostKeys = [
          {
            comment = "${config.networking.hostName}.local";
            path = "/etc/ssh/ssh_host_ed25519_key";
            rounds = 100;
            type = "ed25519";
          }
        ];
      };
    };
  };
}
