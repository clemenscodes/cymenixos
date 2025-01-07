{
  config,
  pkgs,
  ...
}: let
  inherit (config.modules.users) user;
in {
  
  modules = {
    gpu = {
      enable = true;
      amd = {
        enable = true;
      };
    };
    security = {
      enable = true;
      sops = {
        enable = true;
      };
    };
    
    networking = {
      enable = true;
      dns = {
        enable = true;
      };
      stevenblack = {
        enable = true;
      };
      torrent = {
        enable = true;
        mullvadAccountSecretPath = config.sops.secrets.mullvad.path;
        mullvadDns = true;
      };
      vpn = {
        enable = true;
        thm = {
          enable = true;
          usernameFile = config.home-manager.users.${user}.sops.secrets.thmvpnuser.path;
          passwordFile = config.home-manager.users.${user}.sops.secrets.thmvpnpass.path;
        };
      };
      wireless = {
        eduroam = {
          enable = true;
        };
      };
    };
  };
  home-manager = {
    users = {
      ${user} = {
        modules = {
          storage = {
            enable = true;
            rclone = {
              enable = true;
              gdrive = {
                enable = true;
                clientId = config.home-manager.users.${user}.sops.secrets."rclone/gdrive/clientId".path;
                clientSecret = config.home-manager.users.${user}.sops.secrets."rclone/gdrive/clientSecret".path;
                token = config.home-manager.users.${user}.sops.secrets."rclone/gdrive/token".path;
                encryption_password = config.home-manager.users.${user}.sops.secrets."rclone/gdrive/password".path;
                encryption_salt = config.home-manager.users.${user}.sops.secrets."rclone/gdrive/salt".path;
              };
            };
          };
          organization = {
            enable = true;
            email = {
              enable = true;
              accounts = [
                {
                  address = "horn_clemens@t-online.de";
                  primary = true;
                  realName = "Clemens Horn";
                  userName = "horn_clemens@t-online.de";
                  smtpHost = "securesmtp.t-online.de";
                  smtpPort = 465;
                  imapHost = "secureimap.t-online.de";
                  imapPort = 993;
                  secretName = "email/horn_clemens@t-online.de/password";
                }
                {
                  address = "me@clemenshorn.com";
                  primary = false;
                  realName = "Clemens Horn";
                  userName = "me@clemenshorn.com";
                  smtpHost = "box.clemenshorn.com";
                  smtpPort = 465;
                  imapHost = "box.clemenshorn.com";
                  imapPort = 993;
                  secretName = "email/me@clemenshorn.com/password";
                }
                {
                  address = "clemens.horn@mni.thm.de";
                  primary = false;
                  realName = "Clemens Horn";
                  userName = "chrn48";
                  smtpHost = "mailgate.thm.de";
                  smtpPort = 465;
                  imapHost = "mailgate.thm.de";
                  imapPort = 993;
                  secretName = "email/clemens.horn@mni.thm.de/password";
                }
              ];
            };
          };
        };
        programs = {
          zsh = {
            initExtra = let
              gh_token =
                if config.modules.security.sops.enable
                then ''
                  if [[ -o interactive ]]; then
                    export GH_TOKEN=$(${pkgs.bat}/bin/bat ${config.home-manager.users.${user}.sops.secrets.github_token.path} --style=plain)
                  fi
                ''
                else "";
              hetzner_token =
                if config.modules.security.sops.enable
                then ''
                  if [[ -o interactive ]]; then
                    export HCLOUD_TOKEN=$(${pkgs.bat}/bin/bat ${config.home-manager.users.${user}.sops.secrets.hetzner_token.path} --style=plain)
                  fi
                ''
                else "";
              cachix_auth_token =
                if config.modules.security.sops.enable
                then ''
                  if [[ -o interactive ]]; then
                    export CACHIX_AUTH_TOKEN=$(${pkgs.bat}/bin/bat ${config.home-manager.users.${user}.sops.secrets.cachix_auth_token.path} --style=plain)
                  fi
                ''
                else "";
            in
              /*
              bash
              */
              ''
                ${builtins.toString gh_token}
                ${builtins.toString hetzner_token}
                ${builtins.toString cachix_auth_token}
              '';
          };
        };
        nix = {
          extraOptions = ''
            !include ${config.home-manager.users.${user}.sops.secrets.nix_access_tokens.path}
          '';
        };
        sops = {
          defaultSopsFile = ../secrets/secrets.yaml;
          secrets = {
            "email/clemens.horn@mni.thm.de/password" = {};
            "email/horn_clemens@t-online.de/password" = {};
            "email/me@clemenshorn.com/password" = {};
            github_token = {};
            cachix_auth_token = {};
            hetzner_token = {};
            nix_access_tokens = {};
            thmvpnuser = {};
            thmvpnpass = {};
            "rclone/gdrive/clientId" = {};
            "rclone/gdrive/clientSecret" = {};
            "rclone/gdrive/token" = {};
            "rclone/gdrive/password" = {};
            "rclone/gdrive/salt" = {};
          };
        };
      };
    };
  };
}
