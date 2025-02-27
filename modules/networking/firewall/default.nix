{lib, ...}: {config, ...}: let
  cfg = config.modules.networking;
in {
  options = {
    modules = {
      networking = {
        firewall = {
          enable = lib.mkEnableOption "Enable firewall" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.firewall.enable) {
    networking = {
      nftables = {
        inherit (cfg.firewall) enable;
      };
      firewall = {
        inherit (cfg.firewall) enable;
      };
    };
  };
}
