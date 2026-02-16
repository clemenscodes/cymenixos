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
    services.udev.packages = lib.singleton (
      pkgs.writeTextFile
      {
        name = "vfio";
        text = ''
          SUBSYSTEM=="vfio", GROUP="kvm", MODE="0660", TAG+="uaccess"
        '';
        destination = "/etc/udev/rules.d/70-vfio.rules";
      }
    );
  };
}
