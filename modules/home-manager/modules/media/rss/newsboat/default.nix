{lib, ...}: {config, ...}: let
  cfg = config.modules.media.rss;
in {
  options = {
    modules = {
      media = {
        rss = {
          newsboat = {
            enable = lib.mkEnableOption "Enable newsboat rss reader" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.newsboat.enable) {
    programs = {
      newsboat = {
        inherit (cfg.newsboat) enable;
        urls = [
          {
            tags = ["news"];
            title = "Hacker News";
            url = "https://news.ycombinator.com/rss";
          }
        ];
      };
    };
  };
}
