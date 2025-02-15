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
      gnupg = {
        home = "${persistPath}/${home}/.config/gnupg";
        sshKeyPaths = [];
      };
      age = {
        sshKeyPaths = [];
      };
    };
  };
}
