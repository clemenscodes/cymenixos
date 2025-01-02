{lib, ...}: {config, ...}: let
  cfg = config.modules.networking.irc;
in {
  options = {
    modules = {
      networking = {
        irc = {
          irssi = {
            enable = lib.mkEnableOption "Enable irssi" // {default = false;};
            nick = lib.mkOption {
              type = lib.types.str;
              description = "The nick to use for IRC";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.irssi.enable) {
    programs = {
      irssi = {
        inherit (cfg.irssi) enable;
        networks = {
          liberachat = {
            inherit (cfg.irssi) nick;
            server = {
              address = "irc.libera.chat";
              port = 6697;
              autoConnect = true;
            };
            channels = {};
          };
        };
      };
    };
  };
}
