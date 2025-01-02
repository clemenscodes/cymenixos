{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.editor.jetbrains;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
in {
  options = {
    modules = {
      editor = {
        jetbrains = {
          clion = {
            enable = lib.mkEnableOption "Enable CLion" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.clion.enable) {
    home = {
      packages = [pkgs.jetbrains.clion];
    };
  };
}
