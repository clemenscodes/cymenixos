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
  nvim = inputs.cymenixvim.packages.${system}.development;
in {
  options = {
    modules = {
      editor = {
        nvim = {
          enable = lib.mkEnableOption "Enable nvim" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nvim.enable) {
    home = {
      packages = [inputs.cymenixvim.packages.${system}.development];
    };
    programs = {
      zsh = {
        shellAliases = {
          nvim = "${nvim}/bin/nvim";
          vim = "${nvim}/bin/nvim";
          vi = "${nvim}/bin/nvim";
        };
      };
    };
  };
}
