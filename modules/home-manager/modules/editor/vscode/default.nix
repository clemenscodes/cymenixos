{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "vscode"
          "vscode-extension-fill-labs-dependi"
          "vscode-extension-ms-vscode-remote-remote-containers"
          "vscode-extension-ms-vscode-remote-remote-wsl"
          "vscode-extension-ms-vscode-remote-remote-ssh-edit"
        ];
    };
    overlays = [inputs.nix-vscode-extensions.overlays.default];
  };
  codevim = pkgs.writeShellScriptBin "codevim" ''
    nix run github:clemenscodes/codevim -- "$@"
  '';
  cfg = config.modules.editor;
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
        enable = true;
        package = pkgs.vscode;
      };
    };
  };
}
