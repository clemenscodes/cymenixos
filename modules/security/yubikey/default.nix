{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.security;
  viewYubikeyGuide = pkgs.writeShellScriptBin "view-yubikey-guide" ''
    viewer="$(type -P xdg-open || true)"
    if [ -z "$viewer" ]; then
      viewer="${pkgs.glow}/bin/glow -p"
    fi
    exec $viewer "${inputs.yubikey-guide}/README.md"
  '';
  shortcut = pkgs.makeDesktopItem {
    name = "yubikey-guide";
    icon = "${pkgs.yubikey-manager-qt}/share/icons/hicolor/128x128/apps/ykman.png";
    desktopName = "drduh's YubiKey Guide";
    genericName = "Guide to using YubiKey for GnuPG and SSH";
    comment = "Open the guide in a reader program";
    categories = ["Documentation"];
    exec = "${viewYubikeyGuide}/bin/view-yubikey-guide";
  };
  yubikeyGuide = pkgs.symlinkJoin {
    name = "yubikey-guide";
    paths = [viewYubikeyGuide shortcut];
  };
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
        yubikeyGuide
      ];
    };
    system = {
      activationScripts = {
        yubikey-guide = let
          homeDir = "/home/${config.modules.users.name}/";
          desktopDir = homeDir + "Desktop/";
          documentsDir = homeDir + "Documents/";
        in ''
          mkdir -p ${desktopDir} ${documentsDir}
          chown ${config.modules.users.name} ${homeDir} ${desktopDir} ${documentsDir}
          ln -sf ${yubikeyGuide}/share/applications/yubikey-guide.desktop ${desktopDir}
          ln -sfT ${inputs.yubikey-guide} /home/${config.modules.users.name}/Documents/YubiKey-Guide
        '';
      };
    };
  };
}
