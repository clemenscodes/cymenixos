{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-original"
          "steam-run"
          "steam-unwrapped"
          "rpcs3"
        ];
    };
    # Dieses pkgs wird an den gesamten gaming Teilbaum weitergereicht, und
    # ./hyprland, ./steam und ./w3champions ziehen darüber hyprland herein.
    # Ohne das glaze Overlay wäre das ein zweites, ungepatchtes hyprland, das
    # weiterhin am FetchContent Fallback scheitert. Siehe overlays/hyprland.nix.
    overlays = [
      (inputs.lutris-overlay.overlays.lutris)
      (import ../../overlays/hyprland.nix)
    ];
  };
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) name;
in {
  imports = [
    (import ./emulation {inherit inputs pkgs lib;})
    (import ./gamemode {inherit inputs pkgs lib;})
    (import ./heroic {inherit inputs pkgs lib;})
    (import ./hyprland {inherit inputs pkgs lib;})
    (import ./lutris {inherit inputs pkgs lib;})
    (import ./mangohud {inherit inputs pkgs lib;})
    (import ./nexusmods {inherit inputs pkgs lib;})
    (import ./steam {inherit inputs pkgs lib;})
    (import ./umu {inherit inputs pkgs lib;})
    (import ./w3champions {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gaming = {
        enable = lib.mkEnableOption "Enable gaming" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable) {
    environment = {
      systemPackages = with pkgs; [winetricks];
      persistence = {
        ${persistPath} = {
          users = {
            ${name} = {
              directories = ["Games"];
            };
          };
        };
      };
    };
  };
}
