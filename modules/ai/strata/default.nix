{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.ai;
  inherit (config.modules.boot.impermanence) persistPath;

  cudaPkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      cudaSupport = true;
      allowUnfree = true;
    };
  };

  strata = cudaPkgs.callPackage ./package.nix {
    inherit (cfg.strata) cudaArchitectures;
  };
  share = "${strata}/share/strata";
  strataVision = cudaPkgs.callPackage ./vision.nix {
    inherit strata;
    inherit (cfg.strata) cudaArchitectures;
  };
  vision = cfg.strata.vision.enable;

  # the Coder is its own family (half the experts, own repository and expert profile); every other size is the original
  coder = cfg.strata.model == "IQ1_M";
  hf =
    if coder
    then "https://huggingface.co/ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-Coder-GGUF/resolve/main"
    else "https://huggingface.co/ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF/resolve/main";
  tag = lib.optionalString coder "coder-" + cfg.strata.model;
  dataDir = cfg.strata.dataDir;
  modelsDir = "${dataDir}/models/${tag}";
  packDir = "${dataDir}/packs/${lib.toLower tag}";
  mtpDir = "${dataDir}/mtp";
  # the vision encoder: the Coder ships its own copy of the original's file
  mmprojName = "mmproj-Qwen3.8-Flash-Next-BF16.gguf";
  mmproj = "${dataDir}/models/${mmprojName}";
  shard = i: "${modelsDir}/Qwen3.8-Flash-Next-GSQ-RCO-${cfg.strata.model}-0000${toString i}-of-00002.gguf";
  ctx = cfg.strata.context;

  # the same engine arguments setup.py writes into strata-<tag>.json
  engineConfig = {
    exe = "${share}/engine/strata";
    args =
      [
        "--pack"
        packDir
        "--native"
        (shard 1)
        "--ple-gguf"
        (shard 2)
        "--expert-profile"
        "${share}/data/${
          if coder
          then "expert-profile-coder.bin"
          else "expert-profile.bin"
        }"
        "--expert-cache"
        "auto"
        "--prefill"
        "auto"
        "--spec"
        "4"
        "--spec-min-p"
        "0.5"
        "--mtp"
        "${mtpDir}/rt"
        "--max-context"
        (toString ctx)
      ]
      ++ lib.optionals (ctx > 8192) ["--kv" cfg.strata.kv]
      # KV streaming: from 64K the KV cache lives in RAM and the VRAM it frees holds more experts
      ++ lib.optionals (ctx >= 65536 && cfg.strata.kv != "k8v4") ["--kv-resident" "32768"]
      # the encoder warms up before the engine, which then sizes its expert cache around it
      ++ lib.optionals vision ["--vision"]
      ++ lib.optionals (cfg.strata.vramReserveMiB != null) ["--vram-reserve-mib" (toString cfg.strata.vramReserveMiB)]
      ++ cfg.strata.extraArgs;
    cwd = dataDir;
    tokenizer = "${packDir}/tokenizer";
    model_name = "${
      if coder
      then "qwen3.8-flash-next-coder"
      else "qwen3.8-flash-next"
    }-${lib.toLower cfg.strata.model}";
    log = "${dataDir}/strata-${lib.toLower tag}.log";
    lib_dirs = [];
    port = cfg.strata.port;
    host = cfg.strata.host;
    gpu = cfg.strata.gpu;
    gpus_asked = true;
    vision =
      if vision
      then {
        exe = lib.getExe strataVision;
        model = shard 1;
        gpu = true;
        max_tokens = 1024;
        inherit mmproj;
      }
      else null;
  };
  engineConfigFile = pkgs.writeText "strata-${lib.toLower tag}.json" (builtins.toJSON engineConfig);

  # downloads the model, packs it and builds the MTP draft layer, each step skipped once done (setup.py steps 5-6)
  prepare = pkgs.writeShellApplication {
    name = "strata-prepare";
    runtimeInputs = [pkgs.curl pkgs.coreutils];
    text = ''
      export STRATA_GGUF_PY=${share}/gguf-py
      py=${strata}/bin/strata-python
      mkdir -p ${modelsDir} ${mtpDir}
      for i in 1 2; do
        f=${modelsDir}/Qwen3.8-Flash-Next-GSQ-RCO-${cfg.strata.model}-0000$i-of-00002.gguf
        [ -e "$f.done" ] && continue
        echo "downloading $(basename "$f") ..."
        curl -fL --retry 10 --retry-all-errors -C - -o "$f.part" \
          "${hf}/${cfg.strata.model}/$(basename "$f")"
        mv "$f.part" "$f"
        date '+%Y-%m-%d %H:%M' > "$f.done"
      done
      ${lib.optionalString vision ''
        if [ ! -e ${mmproj}.done ]; then
          echo "downloading ${mmprojName} ..."
          curl -fL --retry 10 --retry-all-errors -C - -o ${mmproj}.part "${hf}/${mmprojName}"
          mv ${mmproj}.part ${mmproj}
          date '+%Y-%m-%d %H:%M' > ${mmproj}.done
        fi
      ''}
      if [ ! -e ${packDir}/native_experts.txt ] || [ ! -e ${packDir}/tokenizer/vocab.json ]; then
        "$py" ${share}/tools/iq_pack.py --gguf ${shard 1} --out ${packDir}
      fi
      if [ ! -e ${mtpDir}/rt/experts.bin ]; then
        "$py" ${share}/tools/mtp_fetch.py fetch --out ${mtpDir}
        "$py" ${share}/tools/mtp_pack.py --src ${mtpDir} --experts q2_0 --out ${mtpDir}/mtp-q2_0.gguf
        "$py" ${share}/tools/mtp_rt.py --gguf ${mtpDir}/mtp-q2_0.gguf --out ${mtpDir}/rt
      fi
      [ -e ${mtpDir}/rt/draft_vocab.bin ] || install -m644 ${share}/data/draft_vocab.bin ${mtpDir}/rt/draft_vocab.bin
    '';
  };

  serviceUser = cfg.strata.user;
in {
  options = {
    modules = {
      ai = {
        strata = {
          enable = lib.mkEnableOption "Enable Strata, Qwen3.8-Flash-Next on one GPU plus system RAM";
          autoStart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Start the model at boot. It holds most of the GPU's VRAM and 35-55 GB of RAM while it runs,
              so by default it is started by hand with `systemctl start strata`.
            '';
          };
          model = lib.mkOption {
            type = lib.types.enum ["Q2_0" "IQ2_XS" "IQ3_XXS" "IQ3_S" "IQ1_M"];
            default = "IQ2_XS";
            description = "Model size; IQ1_M is ISTA-DASLab's Coder release (half the experts, ~32 GB RAM)";
          };
          context = lib.mkOption {
            type = lib.types.enum [8192 32768 65536 131072 262144];
            default = 131072;
            description = "Maximum context in tokens";
          };
          kv = lib.mkOption {
            type = lib.types.enum ["int8" "q4_0" "k8v4"];
            default = "int8";
            description = "KV cache precision above 8K context";
          };
          vramReserveMiB = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = 3072;
            description = ''
              VRAM the expert cache leaves free. On a GPU that also drives the desktop the engine's default
              (700 MiB) starves the compositor and browsers flicker; null uses the engine's default.
            '';
          };
          gpu = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "GPU to run on, as nvidia-smi numbers them";
          };
          cudaArchitectures = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["120"];
            description = "CUDA architectures to compile the engine for (120 = RTX 50, 89 = RTX 40, 86 = RTX 30)";
          };
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address the server listens on";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
            description = "Port of the web app and the OpenAI/Anthropic compatible API";
          };
          openFirewall = lib.mkEnableOption "Open the firewall for the Strata port";
          dataDir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/ai/strata";
            description = "Where the model files (~70-85 GB), the pack and the MTP draft layer are kept";
          };
          user = lib.mkOption {
            type = lib.types.str;
            default = "strata";
            description = "User the services run as (created when left at the default)";
          };
          vision = {
            enable = lib.mkEnableOption "Let the model read images (0.9 GB download, ~1.4 GB of VRAM for the encoder)";
          };
          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Extra engine arguments";
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.strata.enable) {
    environment = {
      persistence = lib.mkIf config.modules.boot.enable {
        "${persistPath}" = {
          directories = [cfg.strata.dataDir];
        };
      };
    };

    users = lib.mkIf (serviceUser == "strata") {
      users = {
        strata = {
          isSystemUser = true;
          group = "strata";
          extraGroups = ["video" "render"];
          home = cfg.strata.dataDir;
          createHome = false;
        };
      };
      groups = {
        strata = {};
      };
    };

    systemd = {
      tmpfiles = {
        rules = [
          "d ${cfg.strata.dataDir} 0750 ${serviceUser} - -"
        ];
      };
      services = {
        strata-prepare = {
          description = "Strata: download and prepare the model";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = serviceUser;
            ExecStart = lib.getExe prepare;
            TimeoutStartSec = "infinity";
            WorkingDirectory = cfg.strata.dataDir;
          };
        };
        strata = {
          description = "Strata: Qwen3.8-Flash-Next server";
          requires = ["strata-prepare.service"];
          after = ["strata-prepare.service"];
          wantedBy = lib.mkIf cfg.strata.autoStart ["multi-user.target"];
          environment = {
            STRATA_GGUF_PY = "${share}/gguf-py";
          };
          serviceConfig = {
            User = serviceUser;
            WorkingDirectory = cfg.strata.dataDir;
            # the server keeps its shared settings next to its config, so the config lives in the data folder
            ExecStartPre = "${pkgs.coreutils}/bin/install -m644 ${engineConfigFile} ${cfg.strata.dataDir}/strata.json";
            ExecStart = "${strata}/bin/strata-python ${share}/serve/server.py --engine strata --config ${cfg.strata.dataDir}/strata.json --port ${toString cfg.strata.port}";
            Restart = "on-failure";
            RestartSec = 10;
            TimeoutStartSec = "10min";
            # the engine pins part of the experts in RAM for the GPU
            LimitMEMLOCK = "infinity";
          };
        };
      };
    };

    # the main user starts and stops the model with `systemctl start strata`, no sudo
    security = {
      polkit = {
        enable = true;
        extraConfig =
          /*
          javascript
          */
          ''
            polkit.addRule(function(action, subject) {
              const unit = action.lookup("unit");
              if (action.id == "org.freedesktop.systemd1.manage-units" &&
                  (unit == "strata.service" || unit == "strata-prepare.service") &&
                  subject.user == "${config.modules.users.user}") {
                return polkit.Result.YES;
              }
            });
          '';
      };
    };

    networking = {
      firewall = lib.mkIf cfg.strata.openFirewall {
        allowedTCPPorts = [cfg.strata.port];
      };
    };
  };
}
