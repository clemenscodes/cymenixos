{lib, ...}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.users) user;
in {
  config = lib.mkIf (cfg.enable && cfg.users.enable) {
    users = {
      mutableUsers = true;
      defaultUserShell = lib.mkIf cfg.shell.enable cfg.shell.defaultShell;
      users = {
        ${user} = lib.mkIf (!cfg.security.sops.enable) {
          initialPassword = user;
        };
      };
      groups = {
        ${user} = {};
      };
    };
  };
}
