{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.crypto;
  user = config.modules.users.name;
  homeDir = "/home/${user}";
in {
  config = lib.mkIf (cfg.enable && cfg.monero.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = [
            "/var/lib/monero"
            "/var/log/monero"
          ];
          users.${user} = {
            directories = [
              "Monero"
              ".config/monero-project"
            ];
          };
        };
      };
    };
    home-manager.users.${user} = with cfg.monero.settings; let
      walletPath = "${homeDir}/Monero/wallets/${walletName}/${walletName}";
      guiConfig = pkgs.writeText "monero-core.conf" ''
        [General]
        account_name=${walletName}
        allowRemoteNodeMining=false
        allow_background_mining=false
        allow_p2pool_mining=false
        askDesktopShortcut=false
        askPasswordBeforeSending=true
        askStopLocalNode=true
        autosave=true
        autosaveMinutes=10
        blackTheme=true
        blockchainDataDir=
        bootstrapNodeAddress=
        chainDropdownSelected=0
        checkForUpdates=true
        customDecorations=true
        daemonFlags=
        daemonPassword=
        daemonUsername=
        displayWalletNameInTitleBar=true
        fiatPriceCurrency=xmrusd
        fiatPriceEnabled=false
        fiatPriceProvider=kraken
        fiatPriceToggle=false
        hideBalance=false
        historyHumanDates=true
        historyShowAdvanced=false
        is_recovering=false
        is_recovering_from_device=false
        is_trusted_daemon=true
        kdfRounds=1
        keyReuseMitigation2=true
        language=English (US)
        language_wallet=English
        locale=en_US
        lockOnUserInActivity=true
        lockOnUserInActivityInterval=10
        logCategories=
        logLevel=0
        miningIgnoreBattery=true
        miningModeSelected=0
        nettype=0
        p2poolFlags=
        proxyAddress=127.0.0.1:9050
        proxyEnabled=false
        pruneBlockchain=true
        receiveShowAdvanced=false
        remoteNodeAddress=
        remoteNodesSerialized="{\"selected\":0,\"nodes\":[{\"address\":\"localhost:${builtins.toString rpcPort}\",\"username\":\"\",\"password\":\"\",\"trusted\":true}]}"
        restore_height=0
        segregatePreForkOutputs=true
        segregationHeight=0
        transferShowAdvanced=false
        useRemoteNode=true
        walletMode=2
        wallet_path=${walletPath}
      '';
    in {
      home.activation.moneroGuiConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "${homeDir}/.config/monero-project"
        cp --no-preserve=mode ${guiConfig} "${homeDir}/.config/monero-project/monero-core.conf"
      '';
    };
    systemd = {
      tmpfiles = {
        rules = with cfg.monero.settings; [
          "d ${config.modules.boot.impermanence.persistPath}/var/lib/${monero} 0755 ${monero} ${monero} -"
          "d ${config.modules.boot.impermanence.persistPath}/var/log/${monero} 0750 ${monero} ${monero} -"
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
            prune-blockchain=1
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
            LogsDirectoryMode = "0750";
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
