{lib, ...}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.users) user;
  inherit (lib) mkEnableOption mkIf mkOption types;
in {
  options = {
    modules = {
      users = {
        enable = mkEnableOption "Enable user settings" // {default = false;};
        user = mkOption {
          type = types.str;
          default = "nixos";
        };
        wheel = mkEnableOption "Add user to wheel group" // {default = false;};
        name = mkOption {
          type = types.str;
          default = cfg.users.user;
        };
        uid = mkOption {
          type = types.int;
          default = 1000;
        };
        flake = mkOption {
          type = types.str;
          default = ".local/src/${cfg.hostname.defaultHostname}";
          description = "Where the flake will be, relative to the users home directory";
        };
      };
    };
  };
  config = mkIf (cfg.enable && cfg.users.enable) {
    users = {
      mutableUsers = true;
      defaultUserShell = mkIf cfg.shell.enable cfg.shell.defaultShell;
      users = {
        ${user} = {
          isNormalUser = true;
          description = user;
          group = user;
          hashedPasswordFile = mkIf config.modules.security.sops.enable (config.sops.secrets.password.path);
          initialHashedPassword = mkIf (!config.modules.security.sops.enable && !config.users.users.nixos == "") user;
          extraGroups = [
            (mkIf cfg.users.wheel "wheel")
            (mkIf cfg.crypto.cardanix.enable "cardano-node")
          ];
        };
      };
      groups = {
        ${user} = {};
      };
    };
  };
}
