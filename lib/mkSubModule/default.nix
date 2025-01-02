{lib, ...}: {
  imports ? [],
  module,
  submodule,
  declarations,
}: ({config, ...}: let
  cfg = config.${config.cymenixos.namespace}.${module};
in {
  inherit imports;
  options = {
    ${config.cymenixos.namespace} = {
      ${module} = {
        ${submodule} = {
          enable = lib.mkEnableOption "Enable submodule ${submodule} in ${module} module in ${config.cymenixos.namespace} namespace" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf cfg.${submodule}.enable declarations;
})
