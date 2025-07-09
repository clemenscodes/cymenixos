{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming.emulation;
  ps3bios = import ./firmware {inherit pkgs;};
  rpcs3 = pkgs.rpcs3.overrideAttrs (oldAttrs: {
    version = "0.0.37";
    src = pkgs.fetchFromGitHub {
      owner = "RPCS3";
      repo = "rpcs3";
      rev = "v0.0.37";
      hash = "sha256-/ve1qe76Rc+mXHemq8DI2U9IP6+tPV5m5SNh/wmppEw=";
      fetchSubmodules = true;
    };
    patches = [];
  });
in {
  options = {
    modules = {
      gaming = {
        emulation = {
          rpcs3 = {
            enable = lib.mkEnableOption "Enable rpcs3 emulation (PlayStation 3)" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.rpcs3.enable) {
    services = {
      miniupnpd = {
        enable = true;
        upnp = true;
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${config.modules.users.user} = {
          home = {
            packages = [
              rpcs3
              pkgs.rusty-psn-gui
            ];
            file = {
              ".config/rpcs3/bios" = {
                source = "${ps3bios}/bios";
              };
              ".config/rpcs3/patches/patch.yml" = {
                source = ./patch.yml;
              };
              ".config/rpcs3/Icons/ui" = {
                source = "${rpcs3}/share/rpcs3/Icons/ui";
                recursive = true;
              };
              ".config/rpcs3/GuiConfigs/check_mark_white.png" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/check_mark_white.png";
              };
              ".config/rpcs3/GuiConfigs/list_arrow_blue.png" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/list_arrow_blue.png";
              };
              ".config/rpcs3/GuiConfigs/list_arrow_down_blue.png" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/list_arrow_down_blue.png";
              };
              ".config/rpcs3/GuiConfigs/list_arrow_down_green.png" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/list_arrow_down_green.png";
              };
              ".config/rpcs3/GuiConfigs/list_arrow_down_white.png" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/list_arrow_down_white.png";
              };
              ".config/rpcs3/GuiConfigs/list_arrow_green.png" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/list_arrow_green.png";
              };
              ".config/rpcs3/GuiConfigs/list_arrow_white.png" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/list_arrow_white.png";
              };
              ".config/rpcs3/GuiConfigs/ModernBlue Theme by TheMitoSan.qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/ModernBlue Theme by TheMitoSan.qss";
              };
              ".config/rpcs3/GuiConfigs/Nekotekina by GooseWing.qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/Nekotekina by GooseWing.qss";
              };
              ".config/rpcs3/GuiConfigs/Skyline (Nightfall).qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/Skyline (Nightfall).qss";
              };
              ".config/rpcs3/GuiConfigs/Skyline.qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/Skyline.qss";
              };
              ".config/rpcs3/GuiConfigs/YoRHa by Ani.qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/YoRHa by Ani.qss";
              };
              ".config/rpcs3/GuiConfigs/YoRHa-background.jpg" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/YoRHa-background.jpg";
              };
              ".config/rpcs3/GuiConfigs/Classic (Bright).qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/Classic (Bright).qss";
              };
              ".config/rpcs3/GuiConfigs/Darker Style by TheMitoSan.qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/Darker Style by TheMitoSan.qss";
              };
              ".config/rpcs3/GuiConfigs/Envy.qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/Envy.qss";
              };
              ".config/rpcs3/GuiConfigs/Kuroi (Dark) by Ani.qss" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/Kuroi (Dark) by Ani.qss";
              };
              ".config/rpcs3/GuiConfigs/kot-bg.jpg" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs/kot-bg.jpg";
              };
              ".config/rpcs3/input_configs/active_input_configurations.yml" = {
                text = ''
                  Active Configurations:
                    global: Default
                '';
              };
              ".config/rpcs3/input_configs/global/Default.yml" = {
                text = ''
                  Player 1 Input:
                    Handler: SDL
                    Device: JoyMouse 1
                    Config:
                      Left Stick Left: LS X-
                      Left Stick Down: LS Y-
                      Left Stick Right: LS X+
                      Left Stick Up: LS Y+
                      Right Stick Left: RS X-
                      Right Stick Down: RS Y-
                      Right Stick Right: RS X+
                      Right Stick Up: RS Y+
                      Start: Start
                      Select: Back
                      PS Button: Guide
                      Square: West
                      Cross: South
                      Circle: East
                      Triangle: North
                      Left: Left
                      Down: Down
                      Right: Right
                      Up: Up
                      R1: RB
                      R2: RT
                      R3: RS
                      L1: LB
                      L2: LT
                      L3: LS
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 8000
                      Right Stick Deadzone: 8000
                      Left Stick Anti-Deadzone: 4259
                      Right Stick Anti-Deadzone: 4259
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 20
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 10
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 1356
                      Product ID: 616
                    Buddy Device: ""
                  Player 2 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 3 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 4 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 5 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 6 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 7 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                '';
              };
              ".config/rpcs3/custom_configs/config_BCES00757.yml" = {
                text = ''
                  Core:
                    PPU Decoder: Recompiler (LLVM)
                    PPU Threads: 2
                    PPU Debug: false
                    PPU Calling History: false
                    Save LLVM logs: false
                    Use LLVM CPU: ""
                    Max LLVM Compile Threads: 0
                    PPU LLVM Greedy Mode: false
                    LLVM Precompilation: true
                    Thread Scheduler Mode: Operating System
                    Set DAZ and FTZ: false
                    SPU Decoder: Recompiler (LLVM)
                    SPU Reservation Busy Waiting Percentage 1: 100
                    SPU Reservation Busy Waiting Enabled: false
                    SPU GETLLAR Busy Waiting Percentage: 100
                    Disable SPU GETLLAR Spin Optimization: false
                    SPU Debug: false
                    MFC Debug: false
                    Preferred SPU Threads: 1
                    SPU delay penalty: 3
                    SPU loop detection: false
                    Max SPURS Threads: 6
                    SPU Block Size: Safe
                    Accurate SPU DMA: false
                    Accurate SPU Reservations: true
                    Accurate Cache Line Stores: false
                    Accurate RSX reservation access: true
                    RSX FIFO Accuracy: Atomic
                    SPU Verification: true
                    SPU Cache: true
                    SPU Profiler: false
                    MFC Commands Shuffling Limit: 0
                    MFC Commands Timeout: 0
                    MFC Commands Shuffling In Steps: false
                    Enable TSX: Disabled
                    XFloat Accuracy: Relaxed
                    Accurate PPU 128-byte Reservation Op Max Length: 0
                    Stub PPU Traps: 0
                    Precise SPU Verification: false
                    PPU LLVM Java Mode Handling: true
                    Use Accurate DFMA: true
                    PPU Set Saturation Bit: false
                    PPU Accurate Non-Java Mode: false
                    PPU Fixup Vector NaN Values: false
                    PPU Accurate Vector NaN Values: false
                    PPU Set FPCC Bits: false
                    Debug Console Mode: false
                    Hook static functions: false
                    Libraries Control:
                      []
                    HLE lwmutex: false
                    SPU LLVM Lower Bound: 0
                    SPU LLVM Upper Bound: 18446744073709551615
                    TSX Transaction First Limit: 800
                    TSX Transaction Second Limit: 2000
                    Clocks scale: 100
                    SPU Wake-Up Delay: 0
                    SPU Wake-Up Delay Thread Mask: 63
                    Max CPU Preempt Count: 0
                    Allow RSX CPU Preemptions: true
                    Sleep Timers Accuracy: As Host
                    Usleep Time Addend: 0
                    Performance Report Threshold: 500
                    Enable Performance Report: false
                    Assume External Debugger: false
                    SPU Reservation Busy Waiting Percentage: 0
                  VFS:
                    Enable /host_root/: false
                    Initialize Directories: true
                    Limit disk cache size: false
                    Disk cache maximum size (MB): 5120
                    Empty /dev_hdd0/tmp/: true
                  Video:
                    Renderer: Vulkan
                    Resolution: 1280x720
                    Aspect ratio: 16:9
                    Frame limit: Display
                    Second Frame Limit: 0
                    MSAA: Disabled
                    Shader Mode: Async Shader Recompiler
                    Shader Precision: Ultra
                    Write Color Buffers: true
                    Write Depth Buffer: true
                    Read Color Buffers: false
                    Read Depth Buffer: true
                    Handle RSX Memory Tiling: false
                    Log shader programs: false
                    VSync: true
                    Debug output: false
                    Debug overlay: false
                    Renderdoc Compatibility Mode: false
                    Use GPU texture scaling: false
                    Stretch To Display Area: false
                    Force High Precision Z buffer: false
                    Strict Rendering Mode: false
                    Disable ZCull Occlusion Queries: false
                    Disable Video Output: false
                    Disable Vertex Cache: false
                    Disable FIFO Reordering: false
                    Enable Frame Skip: false
                    Force CPU Blit: false
                    Disable On-Disk Shader Cache: false
                    Disable Vulkan Memory Allocator: false
                    Use full RGB output range: true
                    Strict Texture Flushing: false
                    Multithreaded RSX: true
                    Relaxed ZCULL Sync: false
                    Force Hardware MSAA Resolve: false
                    3D Display Mode: Disabled
                    Debug Program Analyser: false
                    Accurate ZCULL stats: true
                    Consecutive Frames To Draw: 1
                    Consecutive Frames To Skip: 1
                    Resolution Scale: 300
                    Anisotropic Filter Override: 0
                    Texture LOD Bias Addend: 0
                    Minimum Scalable Dimension: 160
                    Shader Compiler Threads: 0
                    Driver Recovery Timeout: 1000000
                    Driver Wake-Up Delay: 1
                    Vblank Rate: 60
                    Vblank NTSC Fixup: false
                    DECR memory layout: false
                    Allow Host GPU Labels: false
                    Disable MSL Fast Math: false
                    Disable Asynchronous Memory Manager: false
                    Output Scaling Mode: FidelityFX Super Resolution
                    Vulkan:
                      Adapter: AMD Radeon RX 7900 XTX (RADV NAVI31)
                      Force FIFO present mode: false
                      Force primitive restart flag: false
                      Exclusive Fullscreen Mode: Automatic
                      Asynchronous Texture Streaming 2: true
                      FidelityFX CAS Sharpening Intensity: 100
                      Asynchronous Queue Scheduler: Safe
                      VRAM allocation limit (MB): 65536
                    Performance Overlay:
                      Enabled: true
                      Enable Framerate Graph: true
                      Enable Frametime Graph: false
                      Framerate datapoints: 199
                      Frametime datapoints: 170
                      Detail level: None
                      Framerate graph detail level: All
                      Frametime graph detail level: All
                      Metrics update interval (ms): 1000
                      Font size (px): 6
                      Position: Top Left
                      Font: n023055ms.ttf
                      Horizontal Margin (px): 10
                      Vertical Margin (px): 10
                      Center Horizontally: false
                      Center Vertically: false
                      Opacity (%): 10
                      Body Color (hex): "#FFE138FF"
                      Body Background (hex): "#002339FF"
                      Title Color (hex): "#F26C24FF"
                      Title Background (hex): "#00000000"
                    Shader Loading Dialog:
                      Allow custom background: true
                      Darkening effect strength: 30
                      Blur effect strength: 0
                  Audio:
                    Renderer: Cubeb
                    Audio Provider: CellAudio
                    RSXAudio Avport: HDMI 0
                    Dump to file: false
                    Convert to 16 bit: false
                    Audio Format: Stereo
                    Audio Formats: 0
                    Audio Channel Layout: Automatic
                    Audio Device: "@@@default@@@"
                    Master Volume: 100
                    Enable Buffering: true
                    Desired Audio Buffer Duration: 100
                    Enable Time Stretching: false
                    Disable Sampling Skip: false
                    Time Stretching Threshold: 75
                    Microphone Type: "Null"
                    Microphone Devices: "@@@@@@@@@@@@"
                    Music Handler: Qt
                  Input/Output:
                    Keyboard: "Null"
                    Mouse: Basic
                    Camera: "Null"
                    Camera type: Unknown
                    Camera flip: None
                    Camera ID: Default
                    Move: "Null"
                    Buzz emulated controller: "Null"
                    Turntable emulated controller: "Null"
                    GHLtar emulated controller: "Null"
                    Pad handler mode: Single-threaded
                    Keep pads connected: false
                    Pad handler sleep (microseconds): 1000
                    Background input enabled: true
                    Show move cursor: false
                    Paint move spheres: false
                    Allow move hue set by game: false
                    Lock overlay input to player one: false
                    Emulated Midi devices: Keyboardßßß@@@Keyboardßßß@@@Keyboardßßß@@@
                    Load SDL GameController Mappings: true
                    IO Debug overlay: false
                    Fake Move Rotation Cone: 10
                    Fake Move Rotation Cone (Vertical): 10
                  System:
                    License Area: SCEE
                    Language: German
                    Keyboard Type: German keyboard
                    Enter button assignment: Enter with cross
                    Console time offset (s): 0
                    System Name: RPCS3-577
                    PSID high: 0
                    PSID low: 0
                    HDD Model Name: ""
                    HDD Serial Number: ""
                    Process ARGV: {}
                  Net:
                    Internet enabled: Connected
                    IP address: 0.0.0.0
                    Bind address: 0.0.0.0
                    DNS address: 51.75.22.125
                    IP swap list: ""
                    UPNP Enabled: true
                    PSN status: RPCN
                    PSN Country: us
                  Savestate:
                    Start Paused: false
                    Suspend Emulation Savestate Mode: false
                    Compatible Savestate Mode: false
                    Inspection Mode Savestates: false
                    Save Disc Game Data: false
                  Miscellaneous:
                    Automatically start games after boot: true
                    Exit RPCS3 when process finishes: false
                    Pause emulation on RPCS3 focus loss: false
                    Start games in fullscreen mode: false
                    Prevent display sleep while running games: true
                    Show trophy popups: true
                    Show RPCN popups: true
                    Show shader compilation hint: true
                    Show PPU compilation hint: true
                    Show autosave/autoload hint: false
                    Show pressure intensity toggle hint: true
                    Show analog limiter toggle hint: true
                    Show mouse and keyboard toggle hint: true
                    Use native user interface: true
                    GDB Server: 127.0.0.1:2345
                    Silence All Logs: false
                    Window Title Format: "FPS: %F | %R | %V | %T [%t]"
                    Pause Emulation During Home Menu: false
                  Log: {}
                '';
              };
            };
            persistence = lib.mkIf config.modules.boot.enable {
              "${config.modules.boot.impermanence.persistPath}/home/${config.modules.users.user}" = {
                directories = [".config/rpcs3"];
              };
            };
          };
        };
      };
    };
  };
}
