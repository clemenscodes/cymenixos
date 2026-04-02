{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.crypto;
  threadFlag =
    if cfg.monero.settings.threads != null
    then " --threads ${builtins.toString cfg.monero.settings.threads}"
    else "";
in {
  config = lib.mkIf (cfg.enable && cfg.monero.enable) {
    systemd = {
      services = with cfg.monero.settings; {
        "${xmrig}" = let
          dependencies = ["network-online.target" "systemd-modules-load.service" "${p2pool}.service" "${monero}.service"];
        in {
          description = "${xmrig} miner";
          after = dependencies;
          wants = dependencies;
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            # xmrig needs cap_ipc_lock for hugepages, cap_sys_nice for priority,
            # and cap_sys_rawio to write AMD MSR registers for RandomX optimization
            AmbientCapabilities = ["CAP_IPC_LOCK" "CAP_SYS_NICE" "CAP_SYS_RAWIO"];
            CapabilityBoundingSet = ["CAP_IPC_LOCK" "CAP_SYS_NICE" "CAP_SYS_RAWIO"];
            LogsDirectory = "${xmrig}";
            LogsDirectoryMode = "0710";
            Restart = "always";
            RestartSec = "30";
            Nice = "-10";
            ExecStart = "${pkgs.xmrig}/bin/xmrig -o ${host}:${builtins.toString p2poolStratumPort} --coin monero -u ${wallet} --http-host ${host} --http-port ${builtins.toString p2poolStratumApiPort} --randomx-1gb-pages -k --api-worker-id ${xmrig}${threadFlag}";
          };
        };
      };
    };
  };
}
