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
        direnv = {
          enable = lib.mkEnableOption "Enable direnv support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.direnv.enable) {
    home = {
      persistence = lib.mkIf osConfig.modules.boot.enable {
       "${osConfig.modules.boot.impermanence.persistPath}" = {
          directories = [".local/share/direnv"];
        };
      };
    };
    programs = {
      direnv = {
        inherit (cfg.direnv) enable;
        enableZshIntegration = lib.mkIf config.modules.shell.enable config.modules.shell.zsh.enable;
        config = {
          global = {
            warn_timeout = "100h";
            hide_env_diff = true;
          };
        };
        nix-direnv = {
          inherit (cfg.direnv) enable;
        };
      };
    };
  };
}
