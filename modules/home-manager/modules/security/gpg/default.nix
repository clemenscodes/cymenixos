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
        pinentryPackage = pkgs.pinentry-gnome3;
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
          # Uncomment and set the following options if needed:
          # default-key = "0xFF00000000000001";
          # trusted-key = "0xFF00000000000001";
          # group = "keygroup = 0xFF00000000000003 0xFF00000000000002 0xFF00000000000001";
          # keyserver = "hkps://keys.openpgp.org";
          # keyserver-options = {
          #   http-proxy = "http://127.0.0.1:8118";
          #   http-proxy = "socks5-hostname://127.0.0.1:9050";
          # };
          # auto-key-locate = "wkd,dane,local";
          # auto-key-retrieve = true;
          # trust-model = "tofu+pgp";
          # list-options = "show-unusable-subkeys";
          # verbose = true;
        };
      };
    };
  };
}
