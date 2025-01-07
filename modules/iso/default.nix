{
  inputs,
  lib,
  ...
}: {
  self,
  config,
  pkgs,
  ...
}: let
  cfg = config.modules;
  dependencies =
    [
      config.system.build.toplevel
      config.system.build.diskoScript
      config.system.build.diskoScript.drvPath
      pkgs.stdenv.drvPath
      pkgs.perlPackages.ConfigIniFiles
      pkgs.perlPackages.FileSlurp
      (pkgs.closureInfo {rootPaths = [];}).drvPath
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
