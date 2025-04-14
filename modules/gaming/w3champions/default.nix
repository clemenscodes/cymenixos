{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming;
in {
  imports = [inputs.w3c.nixosModules.${system}.default];
  options = {
    modules = {
      gaming = {
        w3champions = {
          enable = lib.mkEnableOption "Enable W3Champions" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.w3champions.enable) {
    w3champions = {
      inherit (cfg.w3champions) enable;
      inherit (config.modules.users) name;
    };
  };
}
