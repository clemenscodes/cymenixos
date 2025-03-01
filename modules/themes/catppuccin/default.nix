{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.themes;
in {
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    (import ./home-manager {inherit inputs lib;})
  ];
  options = {
    modules = {
      themes = {
        catppuccin = {
          enable = lib.mkEnableOption "Enable catppuccin theme" // {default = false;};
          flavor = lib.mkOption {
            type = lib.types.enum [
              "latte"
              "frappe"
              "macchiato"
              "mocha"
            ];
            default = "macchiato";
          };
          accent = lib.mkOption {
            type = lib.types.enum [
              "blue"
              "flamingo"
              "green"
              "lavender"
              "maroon"
              "mauve"
              "peach"
              "pink"
              "red"
              "rosewater"
              "sapphire"
              "sky"
              "teal"
              "yellow"
            ];
            default = "blue";
          };
        };
      };
    };
  };
  config = {
    catppuccin = lib.mkIf (cfg.enable && cfg.catppuccin.enable && !config.modules.airgap.offline) {
      inherit (cfg.catppuccin) enable flavor accent;
    };
  };
}
