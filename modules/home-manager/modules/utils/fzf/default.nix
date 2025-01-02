{lib, ...}: {config, ...}: let
  cfg = config.modules.utils;
in {
  options = {
    modules = {
      utils = {
        fzf = {
          enable = lib.mkEnableOption "Enable fzf" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.fzf.enable) {
    programs = {
      fzf = {
        inherit (cfg.fzf) enable;
      };
    };
  };
}
