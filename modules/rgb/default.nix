{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.rgb) enable;
  openrgb = pkgs.openrgb.overrideAttrs (previousAttrs: {
    version = "candidate_1.0rc2-dev";
    src = pkgs.fetchFromGitHub {
      owner = "CalcProgrammer1";
      repo = "OpenRGB";
      rev = "56b75aaffc730f1e28c77d576d94d70983bb1db7";
      hash = "sha256-/jbwP8urk0wgj3KCGuUSwJfbKqSV9GQO/dc5d3ZJiT0=";
    };
    patches = [];
    postPatch = ''
      patchShebangs scripts/build-udev-rules.sh
      substituteInPlace scripts/build-udev-rules.sh \
        --replace /bin/chmod "${pkgs.coreutils}/bin/chmod"
      substituteInPlace scripts/build-udev-rules.sh \
        --replace /usr/bin/env "${pkgs.coreutils}/bin/env"
    '';
  });
in {
  options = {
    modules = {
      rgb = {
        enable = lib.mkEnableOption "Enable RGB" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable && enable) {
    services = {
      hardware = {
        openrgb = {
          inherit enable;
          package = openrgb;
        };
      };
    };
    environment = {
      systemPackages = [openrgb];
    };
  };
}
