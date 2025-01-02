{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = [inputs.ps3-nix.homeManagerModules.default];
  options = {
    modules = {
      gaming = {
        enable = lib.mkEnableOption "Enable home-manager gaming" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.gaming.enable) {
    playstation3 = {
      inherit (cfg.gaming) enable;
      uncharted-reloaded = {
        inherit (cfg.gaming) enable;
      };
    };
  };
}
