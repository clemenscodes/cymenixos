{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.crypto;
  generateWallet = pkgs.writeShellApplication {
    name = "generate-monero-wallet";
    runtimeInputs = [pkgs.monero-cli];
    text = ''
      WALLET_DIR="$(mktemp -d)"
      WALLET_FILE="$WALLET_DIR/xmr-wallet"

      echo ""
      echo "Generating new Monero wallet (offline, no daemon)..."
      echo ""

      monero-wallet-cli \
        --offline \
        --generate-new-wallet "$WALLET_FILE" \
        --password "" \
        --mnemonic-language English \
        --log-file /dev/null \
        --command "exit" 2>&1 \
        | grep -E "(Generated new wallet|View key|NOTE|words|^[a-z].*[a-z]$)" \
        | sed 's/NOTE: the following/\nSEED (write this down offline, never share it):\n/'

      rm -rf "$WALLET_DIR"

      echo ""
      echo "Next steps:"
      echo "  1. Write the 25-word seed on paper. Store it offline. Never photograph it."
      echo "  2. Copy the wallet address (starts with 4...)."
      echo "  3. Set modules.crypto.monero.settings.wallet = \"<address>\" in your config."
      echo "  4. Rebuild: sudo nixos-rebuild switch --flake \"\$FLAKE#\$(hostname)\""
      echo ""
    '';
  };
  mkUser = user: {
    isSystemUser = true;
    group = "${user}";
    description = "${user} daemon user";
    createHome = true;
    home = "/var/lib/${user}";
    homeMode = "0750";
  };
  inherit (config.modules.users) user;
in {
  imports = [
    (import ./monerod {inherit inputs pkgs lib;})
    (import ./p2pool {inherit inputs pkgs lib;})
    (import ./settings {inherit inputs pkgs lib;})
    (import ./xmrig {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      crypto = {
        monero = {
          enable = lib.mkEnableOption "Enable Monero mining stack (monerod + p2pool + xmrig)" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.monero.enable) {
    assertions = [
      {
        assertion = cfg.monero.settings.wallet != "YOUR_WALLET_ADDRESS_HERE";
        message = ''
          modules.crypto.monero.settings.wallet is not set.
          Run `generate-monero-wallet` to create one, then set the address in your config.
        '';
      }
      {
        assertion = !(cfg.monero.settings.useMini && cfg.monero.settings.useNano);
        message = "modules.crypto.monero.settings: useMini and useNano are mutually exclusive.";
      }
    ];
    environment = {
      systemPackages = [
        pkgs.feather      # recommended Monero wallet GUI
        pkgs.monero-gui   # official Monero GUI wallet
        generateWallet    # run: generate-monero-wallet
      ];
    };
    users = with cfg.monero.settings; {
      users = {
        "${monero}" = mkUser monero;
        "${xmrig}" = mkUser xmrig;
        "${p2pool}" = mkUser p2pool;
        ${user} = {
          extraGroups = [monero xmrig p2pool];
        };
      };
      groups = {
        "${monero}" = {};
        "${xmrig}" = {};
        "${p2pool}" = {};
      };
    };
    # Performance governor required for full clock speeds during mining
    powerManagement.cpuFreqGovernor = "performance";
    # Hugepages for RandomX — 3072 x 2MB = 6GB, covers all threads on 9950X3D
    boot = {
      kernel = {
        sysctl = {
          "vm.nr_hugepages" = 3072;
        };
      };
    };
    # MSR access required for RandomX MSR mod (big hashrate boost on Ryzen)
    modules = {
      cpu = {
        msr = {
          enable = true;
        };
      };
    };
    networking = {
      firewall = {
        allowedTCPPorts = with cfg.monero.settings; [
          p2pPort
          rpcPort
          p2poolPort
          p2poolMiniPort
          p2poolNanoPort
          p2poolStratumPort
        ];
      };
    };
  };
}
