{lib, ...}: {config, ...}: let
  cfg = config.modules;
  locale = config.modules.locale.defaultLocale;
  utfLocale =
    if locale == "us"
    then "en_US.UTF-8"
    else "${locale}_${lib.toUpper locale}.UTF-8";
in {
  options = {
    modules = {
      locale = {
        enable = lib.mkEnableOption "Enable locale settings" // {default = false;};
        defaultLocale = lib.mkOption {
          type = lib.types.str;
          default = "us";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.locale.enable) {
    i18n = {
      defaultLocale = utfLocale;
      supportedLocales = ["all"];
      extraLocaleSettings = {
        LC_CTYPE = utfLocale;
        LC_COLLATE = utfLocale;
        LC_ADDRESS = utfLocale;
        LC_IDENTIFICATION = utfLocale;
        LC_MEASUREMENT = utfLocale;
        LC_MONETARY = utfLocale;
        LC_NAME = utfLocale;
        LC_NUMERIC = utfLocale;
        LC_PAPER = utfLocale;
        LC_TELEPHONE = utfLocale;
        LC_TIME = utfLocale;
      };
    };
  };
}
