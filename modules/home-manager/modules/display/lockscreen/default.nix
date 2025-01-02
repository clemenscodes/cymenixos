{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./hyprlock {inherit inputs pkgs lib;})
    (import ./sway-audio-idle-inhibit {inherit inputs pkgs lib;})
    (import ./swaylock {inherit inputs pkgs lib;})
    (import ./swayidle {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        lockscreen = {
          enable = lib.mkEnableOption "Enable lockscreen" // {default = false;};
          defaultLockScreen = lib.mkOption {
            type = lib.types.enum ["hyprlock"];
            default = "hyprlock";
          };
        };
      };
    };
  };
}
