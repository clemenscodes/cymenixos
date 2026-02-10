{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation;
in {
  imports = [(import ./windows {inherit inputs pkgs lib;})];
  options = {
    modules = {
      virtualisation = {
        virt-manager = {
          enable = lib.mkEnableOption "Enable virt-manager" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.virt-manager.enable) {
    programs = {
      virt-manager = {
        inherit (cfg.virt-manager) enable;
      };
    };
    environment = {
      systemPackages = with pkgs; [tigervnc];
    };
  };
}
