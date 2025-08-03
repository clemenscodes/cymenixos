{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming.emulation;
  ps2bios = pkgs.stdenv.mkDerivation {
    name = "ps2bios";
    src = pkgs.fetchzip {
      url = "https://files.ps2-bios.com/ps2-bios-europe.zip";
      sha256 = "sha256-DVLN5O7X7PWJk8AA+2TlhqaiYIWhl9Agcrv7XkMrdk4=";
      stripRoot = false;
    };
    dontBuild = true;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out $out/bios
      cp -r $src/* $out/bios
    '';
  };
in {
  options = {
    modules = {
      gaming = {
        emulation = {
          pcsx2 = {
            enable = lib.mkEnableOption "Enable pcsx2 emulation (PlayStation 2)" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.pcsx2.enable) {
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${config.modules.users.user} = {
          home = {
            packages = [pkgs.pcsx2];
            file = {
              ".config/PCSX2/bios" = {
                source = "${ps2bios}/bios";
              };
            };
          };
        };
      };
    };
  };
}
