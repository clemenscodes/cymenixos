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
          "davinci-resolve"
          "davinci-resolve-studio"
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
          then
            pkgs.davinci-resolve-studio.overrideAttrs (old: {
              passthru =
                old.passthru
                // {
                  davinci = old.passthru.davinci.overrideAttrs (drv: {
                    src = drv.src.overrideAttrs (srcOld: {
                      buildCommand =
                        lib.replaceStrings
                        [
                          ''                            curl \
                                            --retry 3 --retry-delay 3''
                        ]
                        [
                          ''                            curl \
                                            -4 \
                                            --http1.1 \
                                            --retry 10 \
                                            --retry-delay 5 \
                                            --retry-connrefused \
                                            --continue-at - \
                                            --fail \
                                            --location''
                        ]
                        srcOld.buildCommand;
                    });
                  });
                };
            })
          else pkgs.davinci-resolve
        )
      ];
    };
  };
}
