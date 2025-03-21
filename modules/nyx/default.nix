{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = [inputs.chaotic.nixosModules.default];
  options = {
    modules = {
      nyx = {
        enable = lib.mkEnableOption "Enable nyx" // {default = false;};
      };
    };
  };
}
