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
        gpg = {
          enable = lib.mkEnableOption "Enable GPG support" // {default = false;};
          enableDebianKeyring = lib.mkEnableOption "Enable debian keyring" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gpg.enable) {
    services = {
      gpg-agent = {
        inherit (cfg.gpg) enable;
        enableSshSupport = cfg.ssh.enable;
        enableZshIntegration = config.modules.shell.zsh.enable;
        pinentry = {
          package = pkgs.pinentry-gnome3;
        };
        maxCacheTtl = 120;
        defaultCacheTtl = 60;
        extraConfig = ''
          ttyname $GPG_TTY
        '';
      };
    };
    programs = {
      gpg = {
        inherit (cfg.gpg) enable;
        homedir = "${config.xdg.configHome}/gnupg";
        scdaemonSettings = {
          disable-ccid = true;
        };
        settings = {
          personal-cipher-preferences = "AES256 AES192 AES";
          personal-digest-preferences = "SHA512 SHA384 SHA256";
          personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
          default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
          cert-digest-algo = "SHA512";
          s2k-digest-algo = "SHA512";
          s2k-cipher-algo = "AES256";
          charset = "utf-8";
          no-comments = true;
          no-emit-version = true;
          no-greeting = true;
          keyid-format = "0xlong";
          list-options = "show-uid-validity";
          verify-options = "show-uid-validity";
          with-fingerprint = true;
          require-cross-certification = true;
          no-symkey-cache = true;
          armor = true;
          use-agent = true;
          throw-keyids = true;
        };
        publicKeys = let
          debianKeyring = pkgs.stdenv.mkDerivation rec {
            pname = "debian-keyring";
            version = "2024.09.22";

            src = pkgs.fetchurl {
              url = "http://ftp.debian.org/debian/pool/main/d/debian-keyring/debian-keyring_${version}_all.deb";
              sha256 = "sha256-LtCt7zCWIT8cJWqj46IXjXc1q0QKUCoYQRbQ7pQtVss=";
            };

            nativeBuildInputs = [pkgs.dpkg];

            unpackPhase = ''
              dpkg-deb -x $src $out
            '';

            installPhase = ''
              mkdir -p $out/share/keyrings
              cp -r $out/usr/share/keyrings/* $out/share/keyrings/
            '';
          };
          debianDevelopers = {
            source = "${debianKeyring}/share/keyrings/debian-keyring.gpg";
            trust = "ultimate";
          };
        in
          lib.mkIf cfg.gpg.enableDebianKeyring [debianDevelopers];
      };
    };
  };
}
