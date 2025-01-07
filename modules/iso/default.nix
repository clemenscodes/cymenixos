{
  inputs,
  pkgs,
  lib,
  ...
}: {
  self,
  config,
  ...
}: let
  cfg = config.modules;
  dependencies =
    [
      self.nixosConfigurations.iso.config.system.build.toplevel
      self.nixosConfigurations.iso.config.system.build.diskoScript
      self.nixosConfigurations.iso.config.system.build.diskoScript.drvPath
      self.nixosConfigurations.iso.pkgs.stdenv.drvPath
      self.nixosConfigurations.iso.pkgs.perlPackages.ConfigIniFiles
      self.nixosConfigurations.iso.pkgs.perlPackages.FileSlurp
      (self.nixosConfigurations.iso.pkgs.closureInfo {rootPaths = [];}).drvPath
    ]
    ++ builtins.map (i: i.outPath) (builtins.attrValues self.inputs);
  closureInfo = pkgs.closureInfo {rootPaths = dependencies;};
in {
  imports = ["${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"];
  options = {
    modules = {
      iso = {
        enable = lib.mkEnableOption "Enable ISO image" // {default = false;};
        fast = lib.mkEnableOption "Use fast compression" // {default = false;};
      };
    };
  };
  config = lib.mkIf cfg.iso.enable {
    environment = {
      etc = {
        "install-closure" = {
          source = "${closureInfo}/store-paths";
        };
      };
    };
    isoImage = lib.mkIf cfg.iso.fast {
      squashfsCompression = "gzip -Xcompression-level 1";
    };
    system = {
      installer = {
        channel = {
          enable = false;
        };
      };
    };
    modules = {
      disk = {
        enable = lib.mkForce false;
      };
      users = {
        isIso = true;
      };
    };
  };
}
