{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
  inherit (config.modules.users) name;
in {
  options = {
    modules = {
      gaming = {
        mangohud = {
          enable = lib.mkEnableOption "Enable mangohud" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mangohud.enable) {
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${name} = {
          programs = {
            mangohud = {
              inherit (cfg.mangohud) enable;
              enableSessionWide = false;
              package = pkgs.mangohud_git;
              settings = {
                legacy_layout = false;
                custom_text_center = "MangoHud";
                background_alpha = 0.1;
                round_corners = 10;
                background_color = "000000";
                font_file = "/run/current-system/sw/share/X11/fonts/VictorMonoNerdFont-Medium.ttf";
                font_size = 26;
                text_color = "FFFFFF";
                position = "top-left";
                toggle_hud = "Shift_R+F12";

                # GPU monitoring
                pci_dev = "0:03:00.0";
                table_columns = 5;
                gpu_text = "GPU";
                gpu_stats = true;
                gpu_load_change = true;
                gpu_load_value = "50,90";
                gpu_load_color = "FFFFFF,FFAA7F,CC0000";
                gpu_voltage = true;
                gpu_core_clock = true;
                gpu_mem_clock = true;
                gpu_temp = true;
                gpu_mem_temp = true;
                gpu_junction_temp = true;
                gpu_fan = true;
                gpu_power = true;
                gpu_color = "00FF00";

                # CPU monitoring
                cpu_text = "CPU";
                cpu_stats = true;
                cpu_load_change = true;
                cpu_load_value = "50,90";
                cpu_load_color = "FFFFFF,FFAA7F,CC0000";
                cpu_mhz = true;
                cpu_temp = true;
                cpu_power = true;
                cpu_color = "FF0000";

                # Memory monitoring
                vram = true;
                vram_color = "0888FF";
                ram = true;
                ram_color = "00C4FF";

                # Battery monitoring
                battery_watt = true;

                # FPS and performance
                fps = true;
                fps_limit_method = "late";
                toggle_fps_limit = "Shift_L+F1";
                fps_limit = 0;
                fps_color_change = true;
                fps_color = "B22222,FDFD09,39F900";
                fps_value = "30,60";

                # Display info
                resolution = true;
                fsr = true;
                hdr = true;
                refresh_rate = true;
                vsync = 3;
                gl_vsync = "n";

                # System info
                gamemode = true;
                custom_text = "Session:";
                exec = "echo $XDG_SESSION_TYPE";

                # Logging
                output_folder = "/home/${name}.config/MangoHud";
                log_duration = 30;
                autostart_log = 0;
                log_interval = 100;
                toggle_logging = "Shift_L+F2";
                log_versioning = true;

                # Blacklist
                blacklist = "pamac-manager,lact,ghb,bitwig-studio,ptyxis,yumex";
              };
            };
          };
        };
      };
    };
    environment = {
      systemPackages = [
        pkgs.mangohud_git
        pkgs.mangohud32_git
        pkgs.goverlay
      ];
    };
  };
}
