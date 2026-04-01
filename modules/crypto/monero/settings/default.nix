{lib, ...}: {...}: {
  options = {
    modules = {
      crypto = {
        monero = {
          settings = {
            wallet = lib.mkOption {
              type = lib.types.str;
              default = "49j7AMxXgkBVioejSyBkxBXQSfDDVB9U71vqimeaLrDRBeaK5jc3NH5RNBHTgKSofeGWuCqRRUZTDbRcctVswNXEKSwszEN";
              description = "Monero wallet address for mining rewards";
            };
            host = lib.mkOption {
              type = lib.types.str;
              default = "127.0.0.1";
              description = "Localhost bind address";
            };
            monero = lib.mkOption {
              type = lib.types.str;
              default = "monero";
              description = "Service/user name for monerod";
            };
            xmrig = lib.mkOption {
              type = lib.types.str;
              default = "xmrig";
              description = "Service/user name for xmrig";
            };
            p2pool = lib.mkOption {
              type = lib.types.str;
              default = "p2pool";
              description = "Service/user name for p2pool";
            };
            p2pPort = lib.mkOption {
              type = lib.types.int;
              default = 18080;
              description = "Monero P2P port";
            };
            p2poolPort = lib.mkOption {
              type = lib.types.int;
              default = 37889;
              description = "P2Pool main chain port";
            };
            p2poolMiniPort = lib.mkOption {
              type = lib.types.int;
              default = 37888;
              description = "P2Pool mini sidechain port";
            };
            p2poolStratumPort = lib.mkOption {
              type = lib.types.int;
              default = 3333;
              description = "P2Pool stratum port for xmrig";
            };
            p2poolStratumApiPort = lib.mkOption {
              type = lib.types.int;
              default = 3334;
              description = "P2Pool stratum API port";
            };
            zmqPort = lib.mkOption {
              type = lib.types.int;
              default = 18083;
              description = "Monero ZMQ port for p2pool";
            };
            rpcPort = lib.mkOption {
              type = lib.types.int;
              default = 18089;
              description = "Monero restricted RPC port for p2pool";
            };
            rateLimit = lib.mkOption {
              type = lib.types.int;
              default = 128000;
              description = "Monero bandwidth rate limit (kB/s)";
            };
            loglevel = lib.mkOption {
              type = lib.types.int;
              default = 3;
              description = "P2Pool log level (0-6)";
            };
            threads = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "XMRig CPU thread count (null = auto-detect)";
            };
            useMini = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Use P2Pool mini sidechain (recommended for most miners, lower variance)";
            };
          };
        };
      };
    };
  };
}
