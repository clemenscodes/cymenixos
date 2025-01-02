{lib, ...}: module: imports: declarations: ({config, ...}: let
  cfg = config.${module};
in {
  inherit imports;
  options = {
    ${module} = {
      enable = lib.mkEnableOption "Enable ${module}" // {default = false;};
    };
  };
  config = lib.mkIf cfg.enable declarations;
})
