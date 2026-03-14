{lib, ...}: {
  config,
  pkgs,
  ...
}: let
  cfg = config.modules.gpu.nvidia.pyroveil;

  pyroveil = pkgs.stdenv.mkDerivation {
    pname = "pyroveil";
    version = "unstable-2025-11-17";

    src = pkgs.fetchFromGitHub {
      owner = "HansKristian-Work";
      repo = "pyroveil";
      rev = "e1f547372cf1b9d14da56621716d2137088d0061";
      # Run `nix build` once to get the correct hash from the error output.
      hash = "sha256-Ym9dTijzdYOKgHPya2dj+8/e1fJhTeUGKqszSeZ+PB4=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      python3
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
    ];

    meta = with lib; {
      description = "Vulkan layer that roundtrips shaders through GLSL to fix NVIDIA driver GPU hangs (Xid 109)";
      homepage = "https://github.com/HansKristian-Work/pyroveil";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
    };
  };

  # Config for Resident Evil Requiem on NVIDIA (based on PR #27 targeting RE Village
  # on Blackwell+ GPUs). Fixes Xid 109 CTX SWITCH TIMEOUT GPU hangs caused by specific
  # SPIR-V compute and fragment shader patterns emitted by vkd3d-proton.
  # Roundtrips both GLCompute (model 5) and Fragment (model 4) shaders,
  # and disables VK_NV_raw_access_chains which triggers the problematic paths.
  # Reference: https://github.com/HansKristian-Work/pyroveil/pull/27
  re-requiem-config = pkgs.writeText "pyroveil-re-requiem.json" ''
    {
      "version": 2,
      "type": "pyroveil",
      "matches": [
        { "spirvExecutionModel": 5, "action": { "glsl-roundtrip": true } },
        { "spirvExecutionModel": 4, "action": { "glsl-roundtrip": true } }
      ],
      "disabledExtensions": [ "VK_NV_raw_access_chains" ],
      "roundtripCache": "/tmp/pyroveil-re-requiem-cache"
    }
  '';

  # Launch wrapper: sets PYROVEIL=1 to activate the implicit layer and points
  # PYROVEIL_CONFIG at the RE Requiem-specific shader fix config.
  # Usage: launch-re-requiem %command%   (in Steam launch options)
  launch-re-requiem = pkgs.writeShellScriptBin "launch-re-requiem" ''
    export PYROVEIL=1
    export PYROVEIL_CONFIG=${re-requiem-config}
    exec "$@"
  '';
in {
  options = {
    modules = {
      gpu = {
        nvidia = {
          pyroveil = {
            enable =
              lib.mkEnableOption "Enables the pyroveil Vulkan layer for NVIDIA shader roundtrip fixes"
              // {default = false;};
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [launch-re-requiem];
    };

    hardware = {
      graphics = {
        # Adds pyroveil to the Vulkan implicit layer search path.
        # The layer is inactive unless PYROVEIL=1 is set at launch time.
        extraPackages = [pyroveil];
      };
    };
  };
}
