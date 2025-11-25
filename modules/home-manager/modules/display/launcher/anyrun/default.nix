{
  inputs,
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules.display.launcher;
in {
  options = {
    modules = {
      display = {
        launcher = {
          anyrun = {
            enable = lib.mkEnableOption "Enable anyrun" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.anyrun.enable) {
    programs.anyrun = {
      enable = true;
      config = {
        x = {fraction = 0.5;};
        y = {fraction = 0.3;};
        width = {fraction = 0.3;};
        hideIcons = false;
        ignoreExclusiveZones = false;
        layer = "overlay";
        hidePluginInfo = false;
        closeOnClick = false;
        showResultsImmediately = false;
        maxEntries = null;
        plugins = [
          "${pkgs.anyrun}/lib/libapplications.so"
          "${pkgs.anyrun}/lib/libsymbols.so"
        ];
      };
      extraCss =
        /*
        css
        */
        ''
        '';
    };
  };
}
