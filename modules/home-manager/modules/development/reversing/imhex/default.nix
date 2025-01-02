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
        glfw = super.glfw.overrideAttrs (finalAttrs: previousAttrs: {
          postPatch = lib.optionalString super.stdenv.isLinux ''
            substituteInPlace src/wl_init.c \
              --replace-fail "libxkbcommon.so.0" "${lib.getLib super.libxkbcommon}/lib/libxkbcommon.so.0" \
              --replace-fail "libdecor-0.so.0" "${lib.getLib super.libdecor}/lib/libdecor-0.so.0" \
              --replace-fail "libwayland-client.so.0" "${lib.getLib super.wayland}/lib/libwayland-client.so.0" \
              --replace-fail "libwayland-cursor.so.0" "${lib.getLib super.wayland}/lib/libwayland-cursor.so.0" \
              --replace-fail "libwayland-egl.so.1" "${lib.getLib super.wayland}/lib/libwayland-egl.so.1"
          '';
        });
        imhex = super.imhex.overrideAttrs (finalAttrs: previousAttrs: let
          patterns_version = "1.35.3";
          patterns_src = super.fetchFromGitHub {
            owner = "WerWolv";
            repo = "ImHex-Patterns";
            rev = "ImHex-v${patterns_version}";
            hash = "sha256-h86qoFMSP9ehsXJXOccUK9Mfqe+DVObfSRT4TCtK0rY=";
          };
        in rec {
          version = "1.35.3";
          src = super.fetchFromGitHub {
            fetchSubmodules = true;
            owner = "WerWolv";
            repo = previousAttrs.pname;
            rev = "v${version}";
            hash = "sha256-8vhOOHfg4D9B9yYgnGZBpcjAjuL4M4oHHax9ad5PJtA=";
          };
          nativeBuildInputs = [
            super.autoPatchelfHook
            super.cmake
            super.llvm
            super.python3
            super.perl
            super.pkg-config
            super.rsync
          ];
          autoPatchelfIgnoreMissingDeps = ["*.hexpluglib"];
          appendRunpaths = [
            (lib.makeLibraryPath [super.libGL])
            "${placeholder "out"}/lib/imhex/plugins"
          ];
          postInstall = ''
            mkdir -p $out/share/imhex
            rsync -av --exclude="*_schema.json" ${patterns_src}/{constants,encodings,includes,magic,patterns} $out/share/imhex
          '';
        });
      })
    ];
  };
in {
  options = {
    modules = {
      development = {
        reversing = {
          imhex = {
            enable = lib.mkEnableOption "Enable imhex" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.imhex.enable) {
    home = {
      packages = [pkgs.imhex];
    };
  };
}
