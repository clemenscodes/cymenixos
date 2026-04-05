{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.io;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["wootility"];
    };
  };
in {
  options = {
    modules = {
      io = {
        wooting = {
          enable =
            lib.mkEnableOption "Enable support for wooting"
            // {
              default = false;
            };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.wooting.enable) {
    environment.systemPackages = [pkgs.wootility];
    services.udev.packages = [pkgs.wooting-udev-rules];
  };
}
