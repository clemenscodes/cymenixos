{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming.emulation.mgba;
  emulationCfg = config.modules.gaming.emulation;
  home = "/home/${config.modules.users.user}";
  mgbaConfigDir = "${home}/.config/mgba";

  extractZip = name: zipPath: innerFile:
    pkgs.runCommand name {} ''
      mkdir -p $out
      ${pkgs.unzip}/bin/unzip ${zipPath} "${innerFile}" -d $out
    '';

  biosPackage = let
    src = builtins.path {
      path = /. + cfg.biosFile;
      name = "gba_bios_src";
    };
  in
    if lib.hasSuffix ".zip" cfg.biosFile
    then extractZip "mgba-bios" src "gba_bios.bin"
    else
      pkgs.runCommand "mgba-bios" {} ''
        mkdir -p $out
        cp ${src} $out/gba_bios.bin
      '';

  mkRomPackage = rom: let
    resolvedPath =
      if rom.path != null
      then rom.path
      else "${home}/${cfg.romsDirectory}/${rom.innerFile}";
    src = builtins.path {
      path = /. + resolvedPath;
      name = "${rom.name}_src";
    };
  in
    if lib.hasSuffix ".zip" resolvedPath
    then extractZip rom.name src rom.innerFile
    else
      pkgs.runCommand rom.name {} ''
        mkdir -p $out
        cp ${src} "$out/${rom.innerFile}"
      '';

  romsDir = pkgs.symlinkJoin {
    name = "mgba-roms";
    paths = map mkRomPackage cfg.roms;
  };
in {
  options = {
    modules = {
      gaming = {
        emulation = {
          mgba = {
            enable = lib.mkEnableOption "Enable mGBA emulation (Game Boy Advance)" // {default = false;};
            biosFile = lib.mkOption {
              type = lib.types.str;
              default = "${mgbaConfigDir}/gba_bios.bin";
              description = "Absolute path to the GBA BIOS (.bin or .zip)";
            };
            romsDirectory = lib.mkOption {
              type = lib.types.str;
              default = ".config/mgba/roms";
              description = "Directory under home to place ROMs (relative to home)";
            };
            roms = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "Identifier name for the ROM package";
                  };
                  path = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Absolute path to the .zip or .gba file; defaults to romsDirectory/innerFile";
                  };
                  innerFile = lib.mkOption {
                    type = lib.types.str;
                    description = "Filename inside the zip (or target filename for .gba)";
                  };
                };
              });
              default = [];
              description = "List of GBA ROMs to install";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (emulationCfg.enable && cfg.enable) {
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${config.modules.users.user} = {
          home = {
            packages = [pkgs.mgba];
            file = {
              ".config/mgba/gba_bios.bin" = {
                source = "${biosPackage}/gba_bios.bin";
              };
            } // lib.optionalAttrs (cfg.roms != []) {
              "${cfg.romsDirectory}" = {
                source = "${romsDir}";
                recursive = true;
              };
            };
          };
        };
      };
    };
  };
}
