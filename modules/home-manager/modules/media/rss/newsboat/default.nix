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
            tags = ["tech"];
            title = "Hacker News";
            url = "https://news.ycombinator.com/rss";
          }
          {
            tags = ["tech"];
            title = "Hacker Noon";
            url = "https://hackernoon.com/feed";
          }
        ];
        extraConfig = ''
          unbind-key h
          unbind-key j
          unbind-key k
          unbind-key l
          unbind-key g # bound to `sort` by default
          unbind-key G # bound to `rev-sort` by default

          bind-key h quit
          bind-key j down
          bind-key k up
          bind-key l open
          bind-key g home
          bind-key G end
        '';
      };
    };
  };
}
