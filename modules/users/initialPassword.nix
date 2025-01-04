{lib, ...}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.users) user;
in {
  config = lib.mkIf (cfg.enable && cfg.users.enable && !cfg.security.sops.enable) {
    users = {
      users = {
        ${user} = {
          initialPassword = user;
        };
      };
    };
  };
}
