{
  inputs,
  pkgs,
  lib,
  ...
}:
{ config, ... }:
let
  cfg = config.modules.security;
  inherit (config.modules.users) user;
in
{
  options = {
    modules = {
      security = {
        gnupg = {
          enable = lib.mkEnableOption "Enable gnupg" // {
            default = false;
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gnupg.enable) {
    environment = {
      persistence = lib.mkIf config.modules.boot.enable {
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
  };
}
