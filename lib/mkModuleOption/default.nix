{lib, ...}: module: imports: declarations: ({config, ...}: let
  cfg = config.${config.cymenixos.namespace};
in {
  inherit imports;
  options = {
    ${config.cymenixos.namespace} = {
      ${module} = {
        enable = lib.mkEnableOption "Enable ${module} in ${config.cymenixos.namespace} namespace" // {default = false;};
      };
    };
  };
  config = lib.mkIf cfg.enable declarations;
})
