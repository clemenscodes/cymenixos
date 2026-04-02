{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.crypto;
  user = config.modules.users.name;
in {
  config = lib.mkIf (cfg.enable && cfg.monero.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = [
            "/var/lib/monero"
          ];
          users.${user} = {
            directories = [
              "Monero"
            ];
          };
        };
      };
    };
    systemd = {
      tmpfiles = {
        rules = with cfg.monero.settings; [
          "d ${config.modules.boot.impermanence.persistPath}/var/lib/${monero} 0755 ${monero} ${monero} -"
        ];
      };
      services = with cfg.monero.settings; {
        "${monero}" = let
          logsDirectory = "/var/log/${monero}";
          stateDirectory = "/var/lib/${monero}";
          configFile = pkgs.writeText "monero.conf" ''
            data-dir=${stateDirectory}/.bitmonero
            zmq-pub=tcp://${host}:${builtins.toString zmqPort}
            log-file=${logsDirectory}/monerod.log
            p2p-bind-ip=${host}
            p2p-bind-port=${builtins.toString p2pPort}
            rpc-restricted-bind-ip=${host}
            rpc-restricted-bind-port=${builtins.toString rpcPort}
            no-igd=1
            restricted-rpc=1
            enable-dns-blocklist=1
            enforce-dns-checkpointing=1
            confirm-external-bind=1
            add-priority-node=p2pmd.xmrvsbeast.com:18080
            add-priority-node=nodes.hashvault.pro:18080
            out-peers=32
            in-peers=64
            fast-block-sync=1
            limit-rate-up=${builtins.toString rateLimit}
            limit-rate-down=${builtins.toString rateLimit}
          '';
        in {
          description = "${monero} daemon";
          after = ["network.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            User = "${monero}";
            Group = "${monero}";
            StateDirectory = "${monero}";
            StateDirectoryMode = "0755";
            LogsDirectory = "${monero}";
            LogsDirectoryMode = "0710";
            Restart = "always";
            RestartSec = "30";
            SuccessExitStatus = [0 1];
            ExecStart = "${pkgs.monero-cli}/bin/monerod --config-file=${configFile} --non-interactive";
          };
        };
      };
    };
  };
}
