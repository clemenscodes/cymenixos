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
        yubikey = {
          enable = lib.mkEnableOption "Enable yubikey" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.yubikey.enable) {
    hardware = {
      gpgSmartcards = {
        inherit (cfg.yubikey) enable;
      };
    };
    services = {
      pcscd = {
        inherit (cfg.yubikey) enable;
      };
      udev = {
        packages = [pkgs.yubikey-personalization];
      };
    };
    programs = {
      ssh = {
        startAgent = false;
      };
      gnupg = {
        agent = {
          inherit (cfg.yubikey) enable;
          enableSSHSupport = true;
        };
      };
    };
    environment = {
      systemPackages = [
        pkgs.yubikey-manager
        pkgs.yubikey-manager-qt
        pkgs.yubikey-personalization
        pkgs.yubikey-personalization-gui
        pkgs.yubico-piv-tool
        pkgs.yubioath-flutter
      ];
    };
  };
}
