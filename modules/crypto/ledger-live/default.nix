{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.crypto;
in {
  options = {
    modules = {
      crypto = {
        ledger-live = {
          enable = lib.mkEnableOption "Enable ledger-live" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.ledger-live.enable) {
    environment = {
      systemPackages = [pkgs.ledger-live-desktop];
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          users = {
            ${config.modules.users.user} = {
              directories = [".config/Ledger Live"];
            };
          };
        };
      };
    };
    hardware = {
      ledger = {
        inherit (cfg.ledger-live) enable;
      };
    };
  };
}
