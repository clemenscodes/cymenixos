{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.services.evglow;

  extraArgs =
    lib.optionalString (cfg.height != null) " --height ${toString cfg.height}"
    + lib.optionalString (cfg.log != null) " --log ${cfg.log}";
in {
  imports = [inputs.evglow.nixosModules.default];

  options.services.evglow = {
    height = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 300;
      description = ''
        Target height in pixels for the keyboard widget.
        Overrides scale by computing scale = height / natural_height.
        null means no height override (scale is used instead).
      '';
    };

    log = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/tmp/evglow.log";
      description = ''
        Path to a file where log output is appended in addition to stderr.
        Useful when launched via exec-once in Hyprland where stderr is hidden.
        null disables file logging.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Extra CLI arguments derived from height and log options.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.evglow.extraArgs = extraArgs;
  };
}
