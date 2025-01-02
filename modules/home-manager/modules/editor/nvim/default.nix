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
in {
  imports = [inputs.nvim.homeManagerModules.${system}.default];
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
    modules = {
      editor = {
        nixvim = {
          inherit (cfg.nvim) enable;
        };
      };
    };
  };
}
