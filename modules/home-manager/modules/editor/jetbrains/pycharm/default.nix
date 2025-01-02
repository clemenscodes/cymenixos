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
          pycharm = {
            enable = lib.mkEnableOption "Enable PyCharm" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.pycharm.enable) {
    home = {
      packages = [pkgs.pycharm-community];
    };
  };
}
