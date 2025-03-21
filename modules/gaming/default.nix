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
    overlays = let
      mkWinePkgs = {
        final,
        prev,
        version,
        src,
        ...
      }: {
        "wine-bleeding-${version}" = prev.winePackages.unstableFull.overrideAttrs (oldAttrs: rec {
          inherit version src;
          name = "wine-bleeding-${version}";
        });
        "wine-bleeding-winetricks-${version}" = prev.stdenv.mkDerivation {
          name = "wine-bleeding-winetricks-${version}";
          phases = "installPhase";
          installPhase = ''
            mkdir -p $out/bin
            ln -s ${final."wine-bleeding-${version}"}/bin/wine $out/bin/wine64
          '';
        };
        "wine64-bleeding-${version}" = prev.wine64Packages.unstableFull.overrideAttrs (oldAttrs: rec {
          inherit version src;
          name = "wine64-bleeding-${version}";
        });
        "wine64-bleeding-winetricks-${version}" = prev.stdenv.mkDerivation {
          name = "wine64-bleeding-winetricks-${version}";
          phases = "installPhase";
          installPhase = ''
            mkdir -p $out/bin
            ln -s ${final."wine64-bleeding-${version}"}/bin/wine $out/bin/wine64
          '';
        };
        "wine-wow-bleeding-${version}" = prev.wineWowPackages.unstableFull.overrideAttrs (oldAttrs: rec {
          inherit version src;
          name = "wine-wow-bleeding-${version}";
        });
        "wine-wow-bleeding-winetricks-${version}" = prev.stdenv.mkDerivation {
          name = "wine-wow-bleeding-winetricks-${version}";
          phases = "installPhase";
          installPhase = ''
            mkdir -p $out/bin
            ln -s ${final."wine-wow-bleeding-${version}"}/bin/wine $out/bin/wine64
          '';
        };
        "wine-wow64-bleeding-${version}" = prev.wineWow64Packages.unstableFull.overrideAttrs (oldAttrs: rec {
          inherit version src;
          name = "wine-wow64-bleeding-${version}";
        });
        "wine-wow64-bleeding-winetricks-${version}" = prev.stdenv.mkDerivation {
          name = "wine-wow64-bleeding-winetricks-${version}";
          phases = "installPhase";
          installPhase = ''
            mkdir -p $out/bin
            ln -s ${final."wine-wow64-bleeding-${version}"}/bin/wine $out/bin/wine64
          '';
        };
      };
    in [
      (
        final: prev: let
          version = "9.22";
          src = prev.fetchurl rec {
            inherit version;
            url = "https://dl.winehq.org/wine/source/9.x/wine-${version}.tar.xz";
            hash = "sha256-4VDSl0KqVPdo7z6XbthhqqT59IVC5Am+qQLQ9Js1loM=";
          };
        in
          mkWinePkgs {inherit final prev version src;}
      )
      (
        final: prev: let
          version = "10.3";
          src = prev.fetchurl rec {
            inherit version;
            url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz";
            hash = "sha256-3j2I/wBWuC/9/KhC8RGVkuSRT0jE6gI3aOBBnDZGfD4=";
          };
        in
          mkWinePkgs {inherit final prev version src;}
      )
      (
        final: prev: {
          winetricks-fix = prev.stdenv.mkDerivation {
            name = "winetricks-fix";
            phases = "installPhase";
            installPhase = ''
              mkdir -p $out/bin
              ln -s ${final.wineWowPackages.unstableFull}/bin/wine $out/bin/wine64
            '';
          };
        }
      )
      (inputs.chaotic.overlays.default)
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
    (import ./mangohud {inherit inputs pkgs lib;})
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
    chaotic = {
      hdr = {
        inherit (cfg) enable;
        wsiPackage = pkgs.gamescope-wsi_git;
      };
    };
    environment = {
      systemPackages = [
        pkgs.winetricks
        pkgs.proton-ge-custom
        pkgs.vulkanPackages_latest.gfxreconstruct
        pkgs.vulkanPackages_latest.glslang
        pkgs.vulkanPackages_latest.spirv-cross
        pkgs.vulkanPackages_latest.spirv-headers
        pkgs.vulkanPackages_latest.spirv-tools
        pkgs.vulkanPackages_latest.vulkan-extension-layer
        pkgs.vulkanPackages_latest.vulkan-headers
        pkgs.vulkanPackages_latest.vulkan-loader
        pkgs.vulkanPackages_latest.vulkan-tools
        pkgs.vulkanPackages_latest.vulkan-tools-lunarg
        pkgs.vulkanPackages_latest.vulkan-utility-libraries
        pkgs.vulkanPackages_latest.vulkan-validation-layers
        pkgs.vulkanPackages_latest.vulkan-volk
        pkgs.latencyflex-vulkan
        # pkgs.winetricks-fix
        # pkgs.wineWowPackages.unstableFull
        # pkgs."wine-wow64-bleeding-10.3"
        # pkgs."wine-wow64-bleeding-winetricks-10.3"
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
