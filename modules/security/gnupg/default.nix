{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.security;
  inherit (config.modules.users) user;
  gpgAgentConf = pkgs.runCommand "gpg-agent.conf" {} ''
    sed '/pinentry-program/d' ${inputs.drduhConfig}/gpg-agent.conf > $out
    echo "pinentry-program ${pkgs.pinentry.curses}/bin/pinentry" >> $out
  '';
in {
  options = {
    modules = {
      security = {
        gnupg = {
          enable = lib.mkEnableOption "Enable gnupg" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gnupg.enable) {
    environment = {
      persistence = {
        "${config.modules.boot.impermanence.persistPath}" = {
          users = {
            ${config.modules.users.user} = {
              directories = [
                {
                  directory = ".config/gnupg";
                  mode = "0700";
                }
              ];
            };
          };
        };
      };
    };
    programs = {
      gnupg = {
        dirmngr = {
          inherit (cfg.gnupg) enable;
        };
        agent = {
          inherit (cfg.gnupg) enable;
          enableSSHSupport = cfg.ssh.enable;
        };
      };
    };
    security = {
      pam = {
        services = {
          ${user} = {
            gnupg = {
              inherit (cfg.gnupg) enable;
            };
          };
        };
      };
    };
    systemd = {
      user = {
        sockets = {
          gpg-agent = {
            listenStreams = let
              socketDir =
                pkgs.runCommand "gnupg-socketdir" {
                  nativeBuildInputs = [pkgs.python3];
                } ''
                  ${pkgs.python3}/bin/python3 ${import ./gnupgdir.nix {inherit inputs pkgs lib;}} '/home/${config.modules.users.user}/.local/share/gnupg' > $out
                '';
            in [
              "" # unset
              "%t/gnupg/${builtins.readFile socketDir}/S.gpg-agent"
            ];
          };
        };
      };
    };
  };
}
