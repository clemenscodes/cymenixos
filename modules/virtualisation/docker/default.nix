{lib, ...}: {config, ...}: let
  cfg = config.modules.virtualisation;
in {
  options = {
    modules = {
      virtualisation = {
        docker = {
          enable = lib.mkEnableOption "Enable docker" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.docker.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = ["/var/lib/docker"];
        };
      };
    };
    virtualisation = {
      docker = {
        inherit (cfg.docker) enable;
        autoPrune = {
          enable = true;
        };
        enableOnBoot = lib.mkDefault false;
      };
    };
  };
}
