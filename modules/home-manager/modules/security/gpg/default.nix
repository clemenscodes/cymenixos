{
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules.security;
in {
  options = {
    modules = {
      security = {
        gpg = {
          enable = lib.mkEnableOption "Enable GPG support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gpg.enable) {
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [".config/gnupg"];
        };
      };
    };
    services = {
      gpg-agent = {
        inherit (cfg.gpg) enable;
        enableSshSupport = cfg.ssh.enable;
        enableZshIntegration = config.modules.shell.zsh.enable;
        pinentryPackage = pkgs.pinentry-gnome3;
      };
    };
    programs = {
      gpg = {
        inherit (cfg.gpg) enable;
        homedir = "${config.xdg.configHome}/gnupg";
      };
    };
  };
}
