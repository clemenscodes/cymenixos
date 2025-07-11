{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: {
  imports = [inputs.chaotic.nixosModules.default];
  options = {
    modules = {
      nyx = {
        enable = lib.mkEnableOption "Enable nyx" // {default = false;};
      };
    };
  };
}
