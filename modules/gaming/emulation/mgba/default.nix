{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming.emulation.mgba;
  emulationCfg = config.modules.gaming.emulation;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) user;
  home = "/home/${user}";
in {
  options = {
    modules = {
      gaming = {
        emulation = {
          mgba = {
            enable = lib.mkEnableOption "Enable mGBA emulation (Game Boy Advance)" // {default = false;};
            biosPath = lib.mkOption {
              type = lib.types.str;
              default = "${home}/.config/mgba/gba_bios.bin";
              description = "Path to the GBA BIOS file on disk";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (emulationCfg.enable && cfg.enable) {
    environment = {
      persistence = lib.mkIf (config.modules.boot.enable) {
        ${persistPath} = {
          users = {
            ${user} = {
              directories = [".config/mgba"];
            };
          };
        };
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${user} = {
          home = {
            packages = [pkgs.mgba];
            activation.mgbaSetup = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
              mkdir -p "${home}/.config/mgba/roms"
              config_file="${home}/.config/mgba/config.ini"
              if ! ${pkgs.gnugrep}/bin/grep -q '^bios=' "$config_file" 2>/dev/null; then
                if ! ${pkgs.gnugrep}/bin/grep -q '^\[gba\]' "$config_file" 2>/dev/null; then
                  echo '[gba]' >> "$config_file"
                fi
                ${pkgs.gnused}/bin/sed -i '/^\[gba\]/a bios=${cfg.biosPath}' "$config_file"
              fi
            '';
          };
        };
      };
    };
  };
}
