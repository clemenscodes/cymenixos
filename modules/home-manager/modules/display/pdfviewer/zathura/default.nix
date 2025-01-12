{lib, ...}: {config, ...}: let
  cfg = config.modules.display.pdfviewer;
in {
  options = {
    modules = {
      display = {
        pdfviewer = {
          zathura = {
            enable = lib.mkEnableOption "Enable zathura" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.zathura.enable) {
    programs = {
      zathura = {
        inherit (cfg.zathura) enable;
        options = {
          sandbox = "none";
          statusbar-h-padding = 0;
          statusbar-v-padding = 0;
          page-padding = 1;
          selection-clipboard = "clipboard";
          synctex = true;
          synctex-editor-command = ''nvim --headless -c \"VimtexInverseSearch %{line} '%{input}'"'';
        };
        mappings = {
          u = "scroll half-up";
          d = "scroll half-down";
          D = "toggle_page_mode";
          r = "reload";
          R = "rotate";
          K = "zoom in";
          J = "zoom out";
          i = "recolor";
          p = "print";
          g = "goto top";
        };
      };
    };
    xdg = {
      mimeApps = {
        associations = {
          added = {
            "application/pdf" = ["zathura.desktop"];
          };
        };
        defaultApplications = {
          "application/pdf" = ["zathura.desktop"];
        };
      };
    };
  };
}
