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
    overlays = [
      (final: prev: {
        wine-bleeding = prev.winePackages.unstableFull.overrideAttrs (oldAttrs: rec {
          version = "10.3";
          name = "wine-bleeding";
          src = prev.fetchurl rec {
            inherit version;
            url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz";
            hash = "sha256-3j2I/wBWuC/9/KhC8RGVkuSRT0jE6gI3aOBBnDZGfD4=";
          };
        });
        wine64-bleeding = prev.wine64Packages.unstableFull.overrideAttrs (oldAttrs: rec {
          version = "10.3";
          name = "wine64-bleeding";
          src = prev.fetchurl rec {
            inherit version;
            url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz";
            hash = "sha256-3j2I/wBWuC/9/KhC8RGVkuSRT0jE6gI3aOBBnDZGfD4=";
          };
        });
        wine-wow-bleeding = prev.wineWowPackages.unstableFull.overrideAttrs (oldAttrs: rec {
          version = "10.3";
          name = "wine-wow-bleeding";
          src = prev.fetchurl rec {
            inherit version;
            url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz";
            hash = "sha256-3j2I/wBWuC/9/KhC8RGVkuSRT0jE6gI3aOBBnDZGfD4=";
          };
        });
        wine-wow64-bleeding = prev.wineWow64Packages.unstableFull.overrideAttrs (oldAttrs: rec {
          version = "10.3";
          name = "wine-wow64-bleeding";
          src = prev.fetchurl rec {
            inherit version;
            url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz";
            hash = "sha256-3j2I/wBWuC/9/KhC8RGVkuSRT0jE6gI3aOBBnDZGfD4=";
          };
        });
      })
    ];
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
        pkgs.winetricks
        pkgs.winePackages.fonts
        pkgs.wine64-bleeding
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
