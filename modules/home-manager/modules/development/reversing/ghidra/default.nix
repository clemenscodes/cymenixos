{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.development.reversing;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (self: super: {
        ghidra = super.ghidra.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [./powerpc.patch];
        });
        ps3GhidraScripts = super.stdenv.mkDerivation {
          name = "Ps3GhidraScripts";
          src = super.fetchurl {
            url = "https://github.com/clienthax/Ps3GhidraScripts/releases/download/1.069/ghidra_11.0_PUBLIC_20240204_Ps3GhidraScripts.zip";
            sha256 = "04iqfgz1r1a08r2bdd9nws743a7h9gdxqfdf3dxbx10xqnpnwny8";
          };
          nativeBuildInputs = [super.unzip];
          phases = "installPhase";
          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/ghidra/Ghidra/Extensions
            unzip -d $out/lib/ghidra/Ghidra/Extensions $src

            runHook postInstall
          '';
        };
      })
    ];
  };
in {
  options = {
    modules = {
      development = {
        reversing = {
          ghidra = {
            enable = lib.mkEnableOption "Enable ghidra" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ghidra.enable) {
    home = {
      packages = [
        pkgs.ghidra
        pkgs.ps3GhidraScripts
        pkgs.ghidra-extensions.gnudisassembler
        pkgs.ghidra-extensions.sleighdevtools
        pkgs.ghidra-extensions.machinelearning
        pkgs.ghidra-extensions.ghidraninja-ghidra-scripts
      ];
    };
  };
}
