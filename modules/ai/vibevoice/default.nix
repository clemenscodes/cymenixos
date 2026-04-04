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

  # transformers 4.51.3 — the version microsoft/VibeVoice-1.5B was built and tested with.
  # nixpkgs ships 5.x which removed VibeVoice TTS support; use 4.51.3 here.
  transformers451 = cudaPkgs.callPackage ./transformers.nix {};

  # vibevoice PyPI package was built for transformers 4.51.x — no patches needed.
  vibevoicePkg = cudaPkgs.callPackage ./package.nix {inherit transformers451;};

  vibevoiceEnv = cudaPkgs.python3.withPackages (_ps: [vibevoicePkg]);

  # Lightweight HTTP server: loads the model once, serves POST /generate
  # Returns raw WAV bytes.
  serverScript = pkgs.writeText "vibevoice-server.py" ''
    #!/usr/bin/env python3
    """
    VibeVoice TTS HTTP server.
    POST /generate  body: {"text": "...", "voice": "/path/to/ref.wav"}
    GET  /health    returns 200 when model is loaded
    GET  /voices    returns JSON list of voice files from VIBEVOICE_VOICES_DIR
    """
    import io, json, os, threading
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import torch
    import soundfile as sf

    MODEL_PATH = os.environ.get("VIBEVOICE_MODEL", "microsoft/VibeVoice-1.5B")
    VOICES_DIR = os.environ.get("VIBEVOICE_VOICES_DIR", "/var/lib/ai/vibevoice/voices")
    PORT       = int(os.environ.get("VIBEVOICE_PORT", "8020"))
    DEVICE     = "cuda" if torch.cuda.is_available() else "cpu"
    DTYPE      = torch.bfloat16 if DEVICE == "cuda" else torch.float32

    processor = None
    model     = None
    ready     = False
    lock      = threading.Lock()

    def load_model():
        global processor, model, ready
        print(f"Loading VibeVoice from {MODEL_PATH} on {DEVICE}...", flush=True)
        from vibevoice.modular.modeling_vibevoice_inference import VibeVoiceForConditionalGenerationInference
        from vibevoice.processor.vibevoice_processor import VibeVoiceProcessor
        p = VibeVoiceProcessor.from_pretrained(MODEL_PATH)
        m = VibeVoiceForConditionalGenerationInference.from_pretrained(
            MODEL_PATH,
            torch_dtype=DTYPE,
            attn_implementation="sdpa",
            low_cpu_mem_usage=False,
        )
        m = m.to(DEVICE)
        m.eval()
        if hasattr(m, "set_ddpm_inference_steps"):
            m.set_ddpm_inference_steps(num_steps=10)
        processor = p
        model     = m
        ready     = True
        print("Model ready.", flush=True)

    def list_voices():
        if not os.path.isdir(VOICES_DIR):
            return []
        exts = {".wav", ".mp3", ".flac", ".ogg", ".m4a"}
        return sorted(
            os.path.splitext(f)[0]
            for f in os.listdir(VOICES_DIR)
            if os.path.splitext(f)[1].lower() in exts
        )

    def default_voice():
        voices = list_voices()
        if not voices:
            return None
        name = "default" if "default" in voices else voices[0]
        for ext in [".wav", ".mp3", ".flac", ".ogg", ".m4a"]:
            p = os.path.join(VOICES_DIR, name + ext)
            if os.path.exists(p):
                return p
        return None

    def generate_wav(text, voice_path):
        script = f"Speaker 1: {text}"
        inputs = processor(
            text=[script],
            voice_samples=[[voice_path]],
            padding=True,
            return_tensors="pt",
            return_attention_mask=True,
        )
        inputs = {k: v.to(DEVICE) if torch.is_tensor(v) else v for k, v in inputs.items()}
        with lock:
            outputs = model.generate(
                **inputs,
                cfg_scale=1.3,
                tokenizer=processor.tokenizer,
                generation_config={"do_sample": False},
            )
        audio = outputs.speech_outputs[0]
        buf = io.BytesIO()
        if hasattr(audio, "cpu"):
            audio = audio.cpu().float().numpy()
        sf.write(buf, audio.T if audio.ndim == 2 else audio, samplerate=24000, format="WAV")
        return buf.getvalue()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            print(fmt % args, flush=True)

        def send_json(self, code, obj):
            body = json.dumps(obj).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path == "/health":
                self.send_json(200 if ready else 503, {"ready": ready})
            elif self.path == "/voices":
                self.send_json(200, list_voices())
            else:
                self.send_json(404, {"error": "not found"})

        def do_POST(self):
            if self.path != "/generate":
                self.send_json(404, {"error": "not found"})
                return
            if not ready:
                self.send_json(503, {"error": "model not ready yet"})
                return
            length = int(self.headers.get("Content-Length", 0))
            body   = json.loads(self.rfile.read(length) or b"{}")
            text   = body.get("text", "").strip()
            voice  = body.get("voice") or default_voice()
            if not text:
                self.send_json(400, {"error": "text is required"})
                return
            if not voice or not os.path.exists(voice):
                self.send_json(400, {
                    "error": "no voice reference found",
                    "hint": f"add a .wav file to {VOICES_DIR} or pass voice=/abs/path.wav",
                })
                return
            try:
                wav = generate_wav(text, voice)
                self.send_response(200)
                self.send_header("Content-Type", "audio/wav")
                self.send_header("Content-Length", str(len(wav)))
                self.end_headers()
                self.wfile.write(wav)
            except Exception as e:
                import traceback
                self.send_json(500, {"error": str(e), "traceback": traceback.format_exc()})

    threading.Thread(target=load_model, daemon=True).start()
    print(f"Listening on 127.0.0.1:{PORT}", flush=True)
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
  '';

  # CLI wrapper: vibevoice "text" [--voice /path.wav] [-o out.wav] [-p]
  vibevoiceCli = pkgs.writeShellScriptBin "vibevoice" ''
    set -euo pipefail
    PORT="''${VIBEVOICE_PORT:-8020}"
    BASE="http://127.0.0.1:$PORT"
    VOICE=""
    OUTPUT="-"
    PLAY=0

    usage() {
      echo "Usage: vibevoice \"text to speak\" [--voice /path/to/ref.wav] [-o output.wav] [-p]"
      echo "       vibevoice voices          # list available voices"
      echo "       vibevoice health          # check if server is ready"
      echo ""
      echo "  -p, --play    play audio immediately via pw-play"
      echo ""
      echo "The service must be running (systemctl status vibevoice)."
      echo "Drop .wav files in /var/lib/ai/vibevoice/voices/ to add voices."
      exit 0
    }

    [ $# -eq 0 ] && usage

    case "$1" in
      voices) ${pkgs.curl}/bin/curl -sf "$BASE/voices" | ${pkgs.jq}/bin/jq -r '.[]'; exit 0 ;;
      health) ${pkgs.curl}/bin/curl -sf "$BASE/health"; echo; exit 0 ;;
      -h|--help) usage ;;
      -*) echo "Unknown option: $1"; usage ;;
    esac

    TEXT="$1"; shift
    while [ $# -gt 0 ]; do
      case "$1" in
        --voice) VOICE="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -p|--play) PLAY=1; shift ;;
        *) echo "Unknown option: $1"; usage ;;
      esac
    done

    PAYLOAD=$(${pkgs.jq}/bin/jq -n --arg t "$TEXT" --arg v "$VOICE" \
      'if $v == "" then {text:$t} else {text:$t,voice:$v} end')

    if [ "$PLAY" = "1" ]; then
      ${pkgs.curl}/bin/curl -sf -X POST "$BASE/generate" \
        -H "Content-Type: application/json" -d "$PAYLOAD" \
        | ${pkgs.pipewire}/bin/pw-play -
    elif [ "$OUTPUT" = "-" ]; then
      ${pkgs.curl}/bin/curl -sf -X POST "$BASE/generate" \
        -H "Content-Type: application/json" -d "$PAYLOAD"
    else
      ${pkgs.curl}/bin/curl -sf -X POST "$BASE/generate" \
        -H "Content-Type: application/json" -d "$PAYLOAD" -o "$OUTPUT"
      echo "Saved to $OUTPUT" >&2
    fi
  '';
in {
  options = {
    modules = {
      ai = {
        vibevoice = {
          enable = lib.mkEnableOption "Enable VibeVoice local TTS";
          model = lib.mkOption {
            type = lib.types.str;
            default = "vibevoice/VibeVoice-7B";
            description = "HuggingFace model ID to load";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8020;
            description = "Port for the VibeVoice HTTP API";
          };
          openFirewall = lib.mkEnableOption "Open firewall for VibeVoice API port";
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.vibevoice.enable) {
    environment = {
      systemPackages = [
        vibevoiceEnv
        vibevoiceCli
      ];
      persistence = lib.mkIf (config.modules.boot.enable && !cfg.ollama.enable) {
        "${persistPath}" = {
          directories = ["/var/lib/ai/vibevoice"];
        };
      };
    };

    users = {
      users = {
        vibevoice = {
          isSystemUser = true;
          group = "vibevoice";
          home = "/var/lib/ai/vibevoice";
          createHome = false;
        };
      };
      groups = {
        vibevoice = {};
      };
    };

    systemd = {
      tmpfiles = {
        rules = [
          "d /var/lib/ai 0755 root root -"
          "d ${persistPath}/var/lib/ai 0755 root root -"
          "d ${persistPath}/var/lib/ai/vibevoice 0750 vibevoice vibevoice -"
          "d ${persistPath}/var/lib/ai/vibevoice/cache 0750 vibevoice vibevoice -"
          "d ${persistPath}/var/lib/ai/vibevoice/voices 0755 vibevoice vibevoice -"
        ];
      };
      services = {
        vibevoice = {
          description = "VibeVoice TTS HTTP API";
          wantedBy = ["multi-user.target"];
          after = ["network.target"];
          environment = {
            HF_HOME = "/var/lib/ai/vibevoice/cache";
            TRANSFORMERS_CACHE = "/var/lib/ai/vibevoice/cache";
            VIBEVOICE_MODEL = cfg.vibevoice.model;
            VIBEVOICE_VOICES_DIR = "/var/lib/ai/vibevoice/voices";
            VIBEVOICE_PORT = toString cfg.vibevoice.port;
          };
          serviceConfig = {
            User = "vibevoice";
            Group = "vibevoice";
            ExecStart = "${vibevoiceEnv}/bin/python ${serverScript}";
            Restart = "on-failure";
            RestartSec = 10;
            StateDirectory = lib.mkForce [];
            ProtectSystem = lib.mkForce "full";
            ReadWritePaths = lib.mkForce ["/var/lib/ai/vibevoice"];
          };
        };
      };
    };

    networking = {
      firewall = lib.mkIf cfg.vibevoice.openFirewall {
        allowedTCPPorts = [cfg.vibevoice.port];
      };
    };
  };
}
