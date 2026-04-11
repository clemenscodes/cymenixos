{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.crypto;
  threadFlag =
    if cfg.monero.settings.threads != null && cfg.monero.settings.rxAffinity == null
    then " --threads ${builtins.toString cfg.monero.settings.threads}"
    else "";
  affinityConfigFlag =
    if cfg.monero.settings.rxAffinity != null
    then let
      cpuConfig = pkgs.writeText "xmrig-cpu-config.json" (
        builtins.toJSON {
          cpu.rx = map (a: {affinity = a;}) cfg.monero.settings.rxAffinity;
        }
      );
    in " -c ${cpuConfig}"
    else "";
  serviceName = cfg.monero.settings.xmrig;
  xmrig-ensure-running = pkgs.writeShellApplication {
    name = "xmrig-ensure-running";
    runtimeInputs = [pkgs.systemd];
    text = ''
      if systemctl is-active --quiet ${serviceName}.service; then
        exit 0
      fi
      sudo systemctl start ${serviceName}.service
    '';
  };
  xmrig-ensure-stopped = pkgs.writeShellApplication {
    name = "xmrig-ensure-stopped";
    runtimeInputs = [pkgs.systemd];
    text = ''
      if ! systemctl is-active --quiet ${serviceName}.service; then
        exit 0
      fi
      sudo systemctl stop ${serviceName}.service
    '';
  };
in {
  options = {
    modules = {
      crypto = {
        monero = {
          scripts = {
            xmrig-ensure-running = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "xmrig-ensure-running script derivation.";
            };
            xmrig-ensure-stopped = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "xmrig-ensure-stopped script derivation.";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.monero.enable) {
    modules.crypto.monero.scripts = {
      inherit xmrig-ensure-running xmrig-ensure-stopped;
    };
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = [
            "/var/lib/${cfg.monero.settings.xmrig}"
            "/var/log/${cfg.monero.settings.xmrig}"
          ];
        };
      };
      systemPackages = [
        xmrig-ensure-running
        xmrig-ensure-stopped
      ];
    };
    systemd = with cfg.monero.settings; {
      tmpfiles = {
        rules = [
          "d ${config.modules.boot.impermanence.persistPath}/var/lib/${xmrig} 0750 ${xmrig} ${xmrig} -"
          "d ${config.modules.boot.impermanence.persistPath}/var/log/${xmrig} 0750 ${xmrig} ${xmrig} -"
        ];
      };
      services = {
        "${xmrig}" = let
          dependencies = [
            "network-online.target"
            "systemd-modules-load.service"
            "${p2pool}.service"
            "${monero}.service"
          ];
        in {
          description = "${xmrig} miner";
          after = dependencies;
          wants = dependencies;
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            # xmrig needs cap_ipc_lock for hugepages, cap_sys_nice for priority,
            # and cap_sys_rawio to write AMD MSR registers for RandomX optimization
            AmbientCapabilities = [
              "CAP_IPC_LOCK"
              "CAP_SYS_NICE"
              "CAP_SYS_RAWIO"
            ];
            CapabilityBoundingSet = [
              "CAP_IPC_LOCK"
              "CAP_SYS_NICE"
              "CAP_SYS_RAWIO"
            ];
            LogsDirectory = "${xmrig}";
            LogsDirectoryMode = "0750";
            Restart = "always";
            RestartSec = "30";
            Nice = "-10";
            ExecStart = "${pkgs.xmrig}/bin/xmrig -o ${host}:${builtins.toString p2poolStratumPort} --coin monero -u ${wallet} --http-host ${host} --http-port ${builtins.toString p2poolStratumApiPort} --randomx-1gb-pages -k --api-worker-id ${xmrig} --log-file /var/log/${xmrig}/${xmrig}.log${threadFlag}${affinityConfigFlag}";
          };
        };
      };
    };
  };
}
