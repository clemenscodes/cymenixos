{lib, ...}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        printing = {
          enable = lib.mkEnableOption "Enable printing services" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.printing.enable) {
    services = {
      avahi = {
        inherit (cfg.printing) enable;
        publish = {
          inherit (cfg.printing) enable;
          userServices = true;
        };
      };
      printing = {
        inherit (cfg.printing) enable;
        browsing = true;
        listenAddresses = ["*:631"];
        allowFrom = ["all"];
        defaultShared = true;
      };
    };
    networking = {
      firewall = {
        allowedUDPPorts = [631];
        allowedTCPPorts = [631];
      };
    };
  };
}
