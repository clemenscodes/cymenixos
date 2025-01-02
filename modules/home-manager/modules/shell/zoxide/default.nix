{lib, ...}: {config, ...}: let
  cfg = config.modules.shell;
in {
  options = {
    modules = {
      shell = {
        zoxide = {
          enable = lib.mkEnableOption "Enable zoxide" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.zoxide.enable) {
    programs = {
      zoxide = {
        inherit (cfg.zoxide) enable;
        enableZshIntegration = cfg.zsh.enable;
      };
    };
  };
}
