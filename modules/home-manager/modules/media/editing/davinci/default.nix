{
  inputs,
  lib,
  ...
}: {
  system,
  config,
  ...
}: let
  cfg = config.modules.media.editing;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
in {
  options = {
    modules = {
      media = {
        editing = {
          davinci = {
            enable = lib.mkEnableOption "Enable DaVinci Resolve" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.davinci.enable) {
    home = {
      packages = [pkgs.davinci-resolve];
    };
  };
}
