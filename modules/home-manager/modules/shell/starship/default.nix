{lib, ...}: {config, ...}: let
  cfg = config.modules.shell;
in {
  options = {
    modules = {
      shell = {
        starship = {
          enable = lib.mkEnableOption "Enable a pretty starship shell prompt" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.starship.enable) {
    programs = {
      starship = {
        inherit (cfg.starship) enable;
        enableZshIntegration = cfg.zsh.enable;
        settings = {
          add_newline = false;
          command_timeout = 500;
          hostname = {
            style = "bold #ff5555";
          };
          username = {
            format = "[$user]($style) on ";
            show_always = true;
            style_user = "bold #bd93f9";
            style_root = "bright-red bold";
          };
          directory = {
            style = "bold #50fa7b";
            truncation_length = 6;
            truncate_to_repo = true;
            truncation_symbol = ".../";
          };
          line_break = {
            disabled = true;
          };
          cmd_duration = {
            style = "bold #f1fa8c";
          };
          git_branch = {
            format = "[$symbol](green)[$branch]($style)";
            style = "bold #ff79c6";
          };
          git_status = {
            format = "[$all_status$ahead_behind]($style) ";
            style = "bold #ff5555";
            conflicted = " ⚔️  ";
            ahead = " 🏎️ 💨 <== \${count}";
            behind = " 🐢 => \${count}";
            diverged = " 🔱 <== \${ahead_count} 🐢 => \${behind_count}";
            untracked = " 🛤️ -> \${count}";
            stashed = " 📦 ";
            modified = " 📝 => \${count}";
            staged = " 🗃️ -> \${count}";
            renamed = " 📛 <!= \${count}";
            deleted = " 🗑️ <!= \${count}";
          };
          nix_shell = {
            disabled = true;
            format = "via [$symbol]($style)";
            symbol = "❄️ ";
          };
          battery = {
            full_symbol = "🔋";
            charging_symbol = "🔌";
            discharging_symbol = "⚡";
          };
        };
      };
    };
  };
}
