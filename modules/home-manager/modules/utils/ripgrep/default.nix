{lib, ...}: {config, ...}: let
  cfg = config.modules.utils;
in {
  options = {
    modules = {
      utils = {
        ripgrep = {
          enable = lib.mkEnableOption "Enable bat" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ripgrep.enable) {
    programs = {
      ripgrep = {
        inherit (cfg.ripgrep) enable;
        arguments = [
          "--max-columns=150"
          "--max-columns-preview"
          "--hidden"
          "--glob=!.git/*"
          "--smart-case"
          "--colors=line:style:bold"
        ];
      };
    };
  };
}
