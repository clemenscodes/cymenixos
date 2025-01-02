{
  lib,
  config,
  ...
}: {
  imports ? [],
  namespace ? "modules",
  module,
  submodule,
  declarations ? {},
}: let
  cfg = config.${config.cymenixos.namespace}.${module};
in {
  inherit imports;
  options = {
    ${namespace} = {
      ${module} = {
        ${submodule} = {
          enable = lib.mkEnableOption "Enable submodule ${submodule} in ${module} module in ${config.cymenixos.namespace} namespace" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf cfg.${submodule}.enable declarations;
}
