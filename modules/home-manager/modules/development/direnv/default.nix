{lib, ...}: {config, ...}: let
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
    programs = {
      direnv = {
        enable = cfg.direnv.enable;
        enableZshIntegration = config.modules.shell.zsh.enable;
        config = {
          global = {
            warn_timeout = "100h";
            hide_env_diff = true;
          };
        };
        nix-direnv = {
          enable = cfg.direnv.enable;
        };
      };
    };
  };
}
