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
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "davici-resolve"
        ];
    };
  };
in {
  options = {
    modules = {
      media = {
        editing = {
          davinci = {
            enable = lib.mkEnableOption "Enable DaVinci Resolve" // {default = false;};
            studio = lib.mkEnableOption "Enable DaVinci Resolve Studio" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.davinci.enable) {
    home = {
      packages = [
        (
          if cfg.davinci.studio
          then pkgs.davinci-resolve-studio
          else pkgs.davinci-resolve
        )
      ];
    };
  };
}
