{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming.w3champions;
  inherit (config.modules.users) name;
  inherit (config.modules.gaming.w3champions) prefix;
in {
  config = lib.mkIf (cfg.enable && cfg.warcraft.enable) {
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${name} = {
          home = {
            file = {
              "${prefix}/drive_c/Program Files/W3Champions/W3Champions.bat" = {
                text = ''
                  C:
                  cd C:\Program Files\W3Champions\
                  start W3Champions.exe
                  timeout 5
                  net stop "Bonjour Service"
                  net start "Bonjour Service"
                '';
              };
            };
          };
        };
      };
    };
  };
}
