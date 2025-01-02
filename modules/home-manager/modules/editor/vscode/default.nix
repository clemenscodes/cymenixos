{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.editor;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["vscode"];
    };
  };
  code =
    if cfg.vscode.proprietary
    then pkgs.vscode
    else pkgs.vscodium;
  codevim = pkgs.writeShellScriptBin "codevim" ''
    nix run github:clemenscodes/codevim -- "$@"
  '';
in {
  imports = [
    (import ./keybindings.nix {inherit inputs pkgs lib;})
    (import ./settings.nix {inherit inputs pkgs lib;})
    (import ./extensions.nix {inherit inputs pkgs lib;})
    (import ./launcher.nix {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      editor = {
        vscode = {
          enable = lib.mkEnableOption "Enable VSCode" // {default = false;};
          proprietary = lib.mkEnableOption "Use proprietary variant instead of Codium" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.vscode.enable) {
    home = {
      packages = [codevim];
    };
    programs = {
      vscode = {
        inherit (cfg.vscode) enable;
        package = code;
        enableExtensionUpdateCheck = true;
        enableUpdateCheck = true;
      };
    };
  };
}
