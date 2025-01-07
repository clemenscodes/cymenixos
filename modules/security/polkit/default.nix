{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.security;
  polkitagent = import ./polkitagent {inherit inputs pkgs lib;};
in {
  options = {
    modules = {
      security = {
        polkit = {
          enable = lib.mkEnableOption "Enable policy kit" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.polkit.enable) {
    environment = {
      systemPackages = [polkitagent];
    };
    security = {
      polkit = {
        inherit (cfg.polkit) enable;
      };
    };
  };
}
