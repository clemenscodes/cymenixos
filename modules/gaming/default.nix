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
        ];
    };
  };
in {
  imports = [
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
    (import ./battlenet {inherit inputs pkgs lib;})
    (import ./emulation {inherit inputs pkgs lib;})
    (import ./gamemode {inherit inputs pkgs lib;})
    (import ./gamescope {inherit inputs pkgs lib;})
    (import ./lutris {inherit inputs pkgs lib;})
    (import ./steam {inherit inputs pkgs lib;})
    (import ./umu {inherit inputs pkgs lib;})
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
      systemPackages = [
        pkgs.wineWowPackages.unstableFull
        pkgs.winetricks
      ];
    };
    services = {
      pipewire = {
        lowLatency = {
          inherit (cfg) enable;
          quantum = 64;
          rate = 48000;
        };
      };
    };
    nix = {
      settings = {
        substituters = ["https://nix-gaming.cachix.org"];
        trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
      };
    };
  };
}
