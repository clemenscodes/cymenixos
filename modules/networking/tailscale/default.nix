{lib, ...}: {config, ...}: let
  cfg = config.modules.networking;
in {
  options = {
    modules = {
      networking = {
        tailscale = {
          enable = lib.mkEnableOption "Enable Tailscale mesh VPN for remote access" // {default = false;};
          ssh = {
            enable =
              lib.mkEnableOption "Enable Tailscale SSH (auth via tailnet ACLs)"
              // {default = true;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.tailscale.enable) {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        extraUpFlags = lib.optionals cfg.tailscale.ssh.enable ["--ssh"];
      };
    };
    networking = {
      firewall = {
        trustedInterfaces = ["tailscale0"];
      };
    };
    environment = {
      persistence = lib.mkIf config.modules.boot.enable {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = [
            "/var/lib/tailscale"
          ];
        };
      };
    };
  };
}
