{lib, ...}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules.development;
in {
  options = {
    modules = {
      development = {
        cargo = {
          enable = lib.mkEnableOption "Enable cargo caching support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.cargo.enable) {
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [".local/share/cargo"];
        };
      };
    };
  };
}
