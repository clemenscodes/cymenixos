{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.io;
  wootswitchModule =
    if inputs ? wootswitch
    then inputs.wootswitch.nixosModules.default
    else null;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["wootility"];
    };
  };
  wootilityVersion = "5.2.5";
  wootilitySrc = pkgs.fetchurl {
    url = "https://wootility-updates.ams3.cdn.digitaloceanspaces.com/wootility-linux/Wootility-${wootilityVersion}.AppImage";
    hash = "sha256-bDhwlI+zi13xdMXqT5ztzR7RNOLgTBxNtjGkEFezZsw=";
  };
  wootilityContents = pkgs.appimageTools.extract {
    pname = "wootility";
    version = wootilityVersion;
    src = wootilitySrc;
  };
  wootility = pkgs.appimageTools.wrapType2 {
    pname = "wootility";
    version = wootilityVersion;
    src = wootilitySrc;
    nativeBuildInputs = [pkgs.makeWrapper];
    extraInstallCommands = ''
      wrapProgram $out/bin/wootility \
        --add-flags "--disable-gpu-sandbox" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

      for size in 16x16 32x32 48x48 64x64 128x128 256x256 512x512 1024x1024; do
        if [ -f ${wootilityContents}/usr/share/icons/hicolor/$size/apps/wootility.png ]; then
          install -Dm444 ${wootilityContents}/usr/share/icons/hicolor/$size/apps/wootility.png \
            $out/share/icons/hicolor/$size/apps/wootility.png
        fi
      done
    '';
    profile = ''
      export LC_ALL=C.UTF-8
    '';
    extraPkgs = epkgs:
      with epkgs; [
        libxkbfile
      ];
    meta = pkgs.wootility.meta;
  };
  # Electron on Wayland creates its window but doesn't call show() until the
  # single-instance "activate" event fires. The window never appears on first
  # launch; a second invocation signals the running process, which then shows it.
  # This wrapper polls hyprctl for up to 3 s after launch and re-runs the binary
  # if no window appears, replicating that second click automatically.
  wootilityLauncher = pkgs.writeShellApplication {
    name = "wootility-launcher";
    runtimeInputs = [pkgs.hyprland];
    text = ''
      ${wootility}/bin/wootility "$@" &

      for _ in 1 2 3 4 5 6; do
        sleep 0.5
        if hyprctl clients -j 2>/dev/null | grep -qi wootility; then
          wait
          exit 0
        fi
      done

      # No window appeared — trigger the single-instance activate event.
      exec ${wootility}/bin/wootility "$@"
    '';
  };
  wootilityDesktop = pkgs.makeDesktopItem {
    name = "wootility";
    desktopName = "Wootility";
    exec = "${wootilityLauncher}/bin/wootility-launcher";
    icon = "wootility";
    categories = ["Utility"];
  };
in {
  imports = lib.optional (inputs ? wootswitch) inputs.wootswitch.nixosModules.default;
  options = {
    modules = {
      io = {
        wooting = {
          enable =
            lib.mkEnableOption "Enable support for Wooting keyboards"
            // {
              default = false;
            };
          wootswitch = {
            enable =
              lib.mkEnableOption "Enable wootswitch — HID-based profile switcher (no Wootility)";
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.wooting.enable) (
    lib.mkMerge [
      {
        environment = {
          systemPackages = [wootility wootilityLauncher wootilityDesktop];
          persistence = {
            ${config.modules.boot.impermanence.persistPath} = {
              users = {
                ${config.modules.users.user} = {
                  directories = [".config/wootility"];
                };
              };
            };
          };
        };
        services.udev.packages = [pkgs.wooting-udev-rules];
      }
      (lib.mkIf (cfg.wooting.wootswitch.enable && wootswitchModule != null) {
        programs.wootswitch.enable = true;
      })
    ]
  );
}
