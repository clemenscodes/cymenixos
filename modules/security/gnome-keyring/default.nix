{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.security;
in {
  options = {
    modules = {
      security = {
        gnome-keyring = {
          enable = lib.mkEnableOption "Enable gnome-keyring" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gnome-keyring.enable) {
    environment = {
      systemPackages = let
        unlockKeyring = pkgs.writeShellApplication {
          name = "unlock-keyring";
          runtimeInputs = [pkgs.bat];
          text = let
            userSecrets = config.home-manager.users.${config.modules.users.name}.sops.secrets;
          in ''
            echo -n "$(bat ${userSecrets.login_password.path} --style=plain)" | \
              gnome-keyring-daemon \
                --daemonize \
                --replace \
                --unlock \
                --components=secrets
          '';
        };
      in [
        unlockKeyring
      ];
    };
    services = {
      gnome = {
        gnome-keyring = {
          inherit (cfg.gnome-keyring) enable;
        };
      };
    };
  };
}
