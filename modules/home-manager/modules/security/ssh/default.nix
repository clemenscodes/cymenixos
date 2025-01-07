{
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  sshagent = pkgs.writeShellScriptBin "sshagent" ''
    eval "$(${pkgs.openssh}/bin/ssh-agent -s)" && ${pkgs.openssh}/bin/ssh-add
  '';
  cfg = config.modules.security;
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
    home = {
      packages = [
        pkgs.gnome-keyring
        sshagent
      ];
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}/${config.home.homeDirectory}" = {
          directories = [".ssh"];
        };
      };
    };
    services = {
      gnome-keyring = {
        inherit (cfg.ssh) enable;
        components = [
          "ssh"
          "secrets"
        ];
      };
      ssh-agent = {
        inherit (cfg.ssh) enable;
      };
    };
  };
}
