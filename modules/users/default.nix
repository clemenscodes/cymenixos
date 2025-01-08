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
        isIso = mkEnableOption "Use user from iso module instead" // {default = false;};
        initialHashedPassword = mkOption {
          type = types.nullOr types.str;
          default = "";
          description = "The inital hashed password for the user";
        };
      };
    };
  };
  config = mkIf (cfg.enable && cfg.users.enable) {
    users = {
      defaultUserShell = mkIf cfg.shell.enable cfg.shell.defaultShell;
      users = {
        ${user} = {
          isNormalUser = true;
          description = user;
          group = user;
          initialHashedPassword = lib.mkForce cfg.users.initialHashedPassword;
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
