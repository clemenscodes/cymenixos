{
  inputs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.security;
  home = config.home.homeDirectory;
  inherit (osConfig.modules.boot.impermanence) persistPath;
in {
  imports = [inputs.sops-nix.homeManagerModule];
  options = {
    modules = {
      security = {
        sops = {
          enable = lib.mkEnableOption "Enable secrets using SOPS" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (osConfig.modules.security.sops.enable && cfg.enable && cfg.sops.enable) {
    sops = {
      age =
        if osConfig.modules.boot.enable
        then {
          generateKey = true;
          keyFile = "${persistPath}/${home}/.config/sops/age/keys.txt";
          sshKeyPaths = ["${persistPath}/${home}/.ssh/id_ed25519"];
        }
        else {
          generateKey = true;
          keyFile = "/${home}/.config/sops/age/keys.txt";
          sshKeyPaths = ["/${home}/.ssh/id_ed25519"];
        };
    };
  };
}
