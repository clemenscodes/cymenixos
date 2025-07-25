{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming;
in {
  imports = [inputs.lsfg-vk-flake.nixosModules.default];
  options = {
    modules = {
      gaming = {
        lossless = {
          enable = lib.mkEnableOption "Enable lossless scaling" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.lossless.enable) {
    environment = {
      systemPackages = [
        inputs.lsfg-vk-flake.packages.${system}.default
      ];
    };
    services = {
      lsfg-vk = {
        enable = true;
      };
    };
  };
}
