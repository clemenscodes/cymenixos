{lib, ...}: {config, ...}: let
  cfg = config.modules.security;
  sshPort = 22;
in {
  options = {
    modules = {
      security = {
        ssh = {
          enable = lib.mkEnableOption "Enable SSH" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ssh.enable) {
    networking = {
      firewall = {
        allowedTCPPorts = [sshPort];
      };
    };
    services = {
      openssh = {
        inherit (cfg.ssh) enable;
        ports = [sshPort];
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = true;
        };
      };
    };
  };
}
