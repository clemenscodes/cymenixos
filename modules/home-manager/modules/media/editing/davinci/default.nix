{
  inputs,
  lib,
  ...
}: {
  system,
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.media.editing;

  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "davinci-resolve"
          "davinci-resolve-studio"
        ];
    };
  };
in {
  options = {
    modules.media.editing.davinci = {
      enable = lib.mkEnableOption "Enable DaVinci Resolve" // {default = false;};
      studio = lib.mkEnableOption "Enable DaVinci Resolve Studio" // {default = false;};
    };
  };

  config = lib.mkIf (cfg.enable && cfg.davinci.enable) {
    # the Studio activation (license/), the project database and the preferences all live here.
    # The activation must be made on the persistent volume itself: RLM rejects its files once they
    # are copied or restored, even byte for byte, so it can only be persisted, never deployed.
    home.persistence = lib.mkIf (osConfig.modules.boot.enable) {
      "${osConfig.modules.boot.impermanence.persistPath}" = {
        directories = [".local/share/DaVinciResolve"];
      };
    };
    home.packages = [
      (
        if cfg.davinci.studio
        then pkgs.davinci-resolve-studio
        else pkgs.davinci-resolve
      )
    ];
  };
}
