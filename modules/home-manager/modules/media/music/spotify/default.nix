{
  inputs,
  lib,
  ...
}: {
  config,
  osConfig,
  system,
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["spotify"];
    };
  };
  cfg = config.modules.media.music;
  isDesktop = osConfig.modules.display.gui != "headless";
in {
  options = {
    modules = {
      media = {
        music = {
          spotify = {
            enable = lib.mkEnableOption "Enable spotify" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.spotify.enable && isDesktop) {
    home = {
      packages = [pkgs.spotify];
    };
  };
}
