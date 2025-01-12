{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.organization;
  hasSecretsEnabled = osConfig.modules.security.sops.enable && config.modules.security.sops.enable;
  inherit (osConfig.modules.users) user;
in {
  options = {
    modules = {
      organization = {
        email = {
          enable = lib.mkEnableOption "Enable E-Mail support using neomutt" // {default = false;};
          thunderbird = {
            enable = lib.mkEnableOption "Enable thunderbird" // {default = false;};
          };
          accounts = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                address = lib.mkOption {
                  type = lib.types.str;
                };
                primary = lib.mkOption {
                  type = lib.types.bool;
                };
                realName = lib.mkOption {
                  type = lib.types.str;
                };
                userName = lib.mkOption {
                  type = lib.types.str;
                };
                smtpHost = lib.mkOption {
                  type = lib.types.str;
                };
                smtpPort = lib.mkOption {
                  type = lib.types.int;
                };
                imapHost = lib.mkOption {
                  type = lib.types.str;
                };
                imapPort = lib.mkOption {
                  type = lib.types.int;
                };
                secretName = lib.mkOption {
                  type = lib.types.str;
                };
              };
            });
            default = [];
          };
        };
      };
    };
  };
  config = lib.mkIf (hasSecretsEnabled && cfg.enable && cfg.email.enable) {
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [config.accounts.email.maildirBasePath];
        };
      };
      packages = [
        pkgs.abook
        pkgs.lynx
        pkgs.openssl
        pkgs.mailcap
      ];
    };
    services = {
      mbsync = {
        inherit (cfg.email) enable;
        configFile = "${config.home.homeDirectory}/.config/isyncrc";
        frequency = "*:*:0/10";
      };
      imapnotify = {
        inherit (cfg.email) enable;
      };
    };
    programs = {
      thunderbird = {
        inherit (cfg.email.thunderbird) enable;
        profiles = {
          ${user} = {
            isDefault = true;
            search = {
              default = "DuckDuckGo";
              privateDefault = "DuckDuckGo";
              order = ["DuckDuckGo"];
            };
          };
        };
      };
    };
    xdg = {
      configFile = {
        "neomutt/mailcap" = {
          text = ''
            text/plain; $EDITOR %s ;
            text/html; ${pkgs.zathura}/bin/zathura %s ; nametemplate=%s.html
            text/html; ${pkgs.lynx}/bin/lynx -assume_charset=%{charset} -display_charset=utf-8 -dump -width=1024 %s; nametemplate=%s.html; copiousoutput;
            image/*; ${pkgs.zathura}/bin/zathura %s ;
            video/*; ${pkgs.util-linux}/bin/setsid ${pkgs.mpv}/bin/mpv --quiet %s &; copiousoutput
            audio/*; ${pkgs.mpv}/bin/mpv %s ;
            application/pdf; ${pkgs.zathura}/bin/zathura %s ;
            application/pgp-encrypted; ${pkgs.gnupg}/bin/gpg -d '%s'; copiousoutput;
            application/pgp-keys; ${pkgs.gnupg}/bin/gpg --import '%s'; copiousoutput;
            application/x-subrip; $EDITOR %s ;
          '';
        };
      };
    };
    accounts = {
      email = let
        mkEmailAccount = {
          primary,
          address,
          realName,
          userName,
          smtpHost,
          smtpPort,
          imapHost,
          imapPort,
          secretName,
        }: let
          pw = "${pkgs.bat}/bin/bat ${config.sops.secrets.${secretName}.path} --style=plain";
        in {
          inherit primary address userName realName;
          passwordCommand = pw;
          imapnotify = {
            boxes = ["Inbox"];
            enable = true;
            onNotify = "${pkgs.isync}/bin/mbsync -a";
            onNotifyPost = ''${pkgs.notmuch}/bin/notmuch new && ${pkgs.libnotify}/bin/notify-send "===> 📬 <===" "Mail received"'';
          };
          thunderbird = {
            inherit (cfg.email.thunderbird) enable;
            profiles = [user] 
          };
          mbsync = {
            inherit (cfg.email) enable;
            create = "both";
            expunge = "both";
            patterns = ["*"];
            extraConfig = {
              channel = {
                MaxMessages = 10000;
                ExpireUnread = "no";
              };
              account = {
                AuthMechs = "LOGIN";
              };
            };
          };
          notmuch = {
            inherit (cfg.email) enable;
            neomutt = {
              inherit (cfg.email) enable;
            };
          };
          neomutt = {
            inherit (cfg.email) enable;
            sendMailCommand = "${pkgs.msmtp}/bin/msmtp -a ${address}";
            extraConfig = ''
              set sort = reverse-date
            '';
          };
          msmtp = {
            inherit (cfg.email) enable;
            extraConfig = {
              auth = "on";
              passwordeval = ''"${pw}"'';
            };
          };
          smtp = {
            host = smtpHost;
            port = smtpPort;
            tls = {
              enable = true;
            };
          };
          imap = {
            host = imapHost;
            port = imapPort;
            tls = {
              enable = true;
            };
          };
        };
      in {
        maildirBasePath = "${config.xdg.dataHome}/mail";
        accounts = let
          mkAccount = config: {
            "${config.address}" = mkEmailAccount {
              inherit (config) primary address realName userName smtpHost smtpPort imapHost imapPort secretName;
            };
          };
          mergeAttrs = attrs: builtins.foldl' (acc: attr: acc // attr) {} attrs;
        in
          mergeAttrs (map mkAccount cfg.email.accounts);
      };
    };
    programs = {
      msmtp = {
        inherit (cfg.email) enable;
      };
      mbsync = {
        inherit (cfg.email) enable;
      };
      notmuch = {
        inherit (cfg.email) enable;
        maildir = {
          synchronizeFlags = true;
        };
        new = {
          tags = [
            "unread"
            "inbox"
          ];
          ignore = [
            ".mbsyncstate"
            ".uivalidity"
          ];
        };
        extraConfig = {
          crypto = {
            gpg_path = "gpg";
          };
        };
      };
      neomutt = {
        inherit (cfg.email) enable;
        sidebar = {
          enable = true;
          width = 22;
          shortPath = true;
          format = ''"%D%?F? [%F]?%* %?N?%N/? %?S?%S?"'';
        };
        sort = "reverse-date";
        binds = [
          {
            map = ["index" "pager"];
            key = "i";
            action = "noop";
          }
          {
            map = ["index" "pager"];
            key = "g";
            action = "noop";
          }
          {
            map = ["index" "pager"];
            key = "M";
            action = "noop";
          }
          {
            map = ["index" "pager"];
            key = "C";
            action = "noop";
          }
          {
            map = ["index"];
            key = ''\Cf'';
            action = "noop";
          }
          {
            map = ["index"];
            key = ''gg'';
            action = "first-entry";
          }
          {
            map = ["index"];
            key = ''j'';
            action = "next-entry";
          }
          {
            map = ["index"];
            key = "k";
            action = "previous-entry";
          }
          {
            map = ["attach"];
            key = "<return>";
            action = "view-mailcap";
          }
          {
            map = ["attach"];
            key = "l";
            action = "view-mailcap";
          }
          {
            map = ["editor"];
            key = "<space>";
            action = "noop";
          }
          {
            map = ["index"];
            key = "G";
            action = "last-entry";
          }
          {
            map = ["pager" "attach"];
            key = "h";
            action = "exit";
          }
          {
            map = ["pager"];
            key = "j";
            action = "next-line";
          }
          {
            map = ["pager"];
            key = "k";
            action = "previous-line";
          }
          {
            map = ["pager"];
            key = "l";
            action = "view-attachments";
          }
          {
            map = ["index"];
            key = "D";
            action = "delete-message";
          }
          {
            map = ["index"];
            key = "U";
            action = "undelete-message";
          }
          {
            map = ["index"];
            key = "L";
            action = "limit";
          }
          {
            map = ["index"];
            key = "h";
            action = "noop";
          }
          {
            map = ["index"];
            key = "l";
            action = "display-message";
          }
          {
            map = ["index" "query"];
            key = "<space>";
            action = "tag-entry";
          }
          {
            map = ["index" "pager"];
            key = "H";
            action = "view-raw-message";
          }
          {
            map = ["browser"];
            key = "l";
            action = "select-entry";
          }
          {
            map = ["browser"];
            key = "gg";
            action = "top-page";
          }
          {
            map = ["browser"];
            key = "G";
            action = "bottom-page";
          }
          {
            map = ["pager"];
            key = "gg";
            action = "top";
          }
          {
            map = ["pager"];
            key = "G";
            action = "bottom";
          }
          {
            map = ["index" "pager" "browser"];
            key = "d";
            action = "half-down";
          }
          {
            map = ["index" "pager" "browser"];
            key = "u";
            action = "half-up";
          }
          {
            map = ["index" "pager"];
            key = "S";
            action = "sync-mailbox";
          }
          {
            map = ["index" "pager"];
            key = "R";
            action = "group-reply";
          }
          {
            map = ["index"];
            key = ''\031'';
            action = "previous-undeleted";
          }
          {
            map = ["index"];
            key = ''\005'';
            action = "next-undeleted";
          }
          {
            map = ["pager"];
            key = ''\031'';
            action = "previous-line";
          }
          {
            map = ["pager"];
            key = ''\005'';
            action = "next-line";
          }
          {
            map = ["editor"];
            key = "<Tab>";
            action = "complete-query";
          }
          {
            map = ["index" "pager"];
            key = ''\Ck'';
            action = "sidebar-prev";
          }
          {
            map = ["index" "pager"];
            key = ''\Cj'';
            action = "sidebar-next";
          }
          {
            map = ["index" "pager"];
            key = ''\Co'';
            action = "sidebar-open";
          }
          {
            map = ["index" "pager"];
            key = ''\Cp'';
            action = "sidebar-prev-new";
          }
          {
            map = ["index" "pager"];
            key = ''\Cn'';
            action = "sidebar-next-new";
          }
          {
            map = ["index" "pager"];
            key = "B";
            action = "sidebar-toggle-visible";
          }
        ];
        macros = let
          inherit (cfg.email) accounts;
          generateAction = address: "<sync-mailbox><enter-command>source ${config.xdg.configHome}/neomutt/${address}<enter><change-folder>!<enter>;<check-stats>";
          inboxes =
            lib.map (account: {
              action = generateAction account.address;
              map = ["index" "pager"];
              key = "i${toString ((lib.lists.findFirstIndex (a: a == account) 0 accounts) + 1)}";
            })
            accounts;
        in
          inboxes
          ++ [
            {
              map = ["browser"];
              key = "h";
              action = "<change-dir><kill-line>..<enter>";
            }
            {
              map = ["index" "pager"];
              key = "gi";
              action = "<change-folder>=Inbox<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Mi";
              action = ";<save-message>=Inbox<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Ci";
              action = ";<copy-message>=Inbox<enter>";
            }
            {
              map = ["index" "pager"];
              key = "gd";
              action = "<change-folder>=Drafts<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Md";
              action = ";<save-message>=Drafts<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Cd";
              action = ";<copy-message>=Drafts<enter>";
            }
            {
              map = ["index" "pager"];
              key = "gj";
              action = "<change-folder>=Junk<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Mj";
              action = ";<save-message>=Junk<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Cj";
              action = ";<copy-message>=Junk<enter>";
            }
            {
              map = ["index" "pager"];
              key = "gt";
              action = "<change-folder>=Trash<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Mt";
              action = ";<save-message>=Trash<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Ct";
              action = ";<copy-message>=Trash<enter>";
            }
            {
              map = ["index" "pager"];
              key = "gs";
              action = "<change-folder>=Sent<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Ms";
              action = ";<save-message>=Sent<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Cs";
              action = ";<copy-message>=Sent<enter>";
            }
            {
              map = ["index" "pager"];
              key = "ga";
              action = "<change-folder>=Archive<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Ma";
              action = ";<save-message>=Archive<enter>";
            }
            {
              map = ["index" "pager"];
              key = "Ca";
              action = ";<copy-message>=Archive<enter>";
            }
            {
              map = ["index"];
              key = "A";
              action = ''<limit>all\n'';
            }
            {
              map = ["index"];
              key = ''\Cr'';
              action = ''<tag-pattern>~N<enter><tag-prefix><clear-flag>N<untag-pattern>.<enter>'';
            }
          ];
        settings = {
          send_charset = ''"us-ascii:utf-8"'';
          mailcap_path = ''"$HOME/.config/neomutt/mailcap"'';
          mime_type_query_command = ''"file --mime-type -b %s"'';
          date_format = ''"%y/%m/%d %I:%M%p"'';
          index_format = ''"%2C %Z %?X?A& ? %D %-15.15F %s (%-4.4c)"'';
          smtp_authenticators = "'gssapi:login'";
          query_command = ''"${pkgs.abook}/bin/abook --mutt-query '%s'"'';
          rfc2047_parameters = "yes";
          sleep_time = "0";
          markers = "no";
          mark_old = "no";
          mime_forward = "no";
          forward_attachments = "yes";
          wait_key = "no";
          forward_format = ''"Fwd: %s"'';
          mail_check = "60";
          sort = "reverse-date";
        };
        extraConfig = ''
          set fast_reply
          set fcc_attach
          set forward_quote
          set reverse_name
          set include
          auto_view text/html # automatically show html (mailcap uses lynx)
          auto_view application/pgp-encrypted

          # Default index colors:
          color index yellow default '.*'
          color index_author red default '.*'
          color index_number blue default
          color index_subject cyan default '.*'

          # New mail is boldened:
          color index brightyellow black "~N"
          color index_author brightred black "~N"
          color index_subject brightcyan black "~N"

          # Tagged mail is highlighted:
          color index brightyellow blue "~T"
          color index_author brightred blue "~T"
          color index_subject brightcyan blue "~T"

          # Flagged mail is highlighted:
          color index brightgreen default "~F"
          color index_subject brightgreen default "~F"
          color index_author brightgreen default "~F"

          # Other colors and aesthetic settings:
          mono bold bold
          mono underline underline
          mono indicator reverse
          mono error bold
          color normal default default
          color indicator brightblack white
          color sidebar_highlight red default
          color sidebar_divider brightblack black
          color sidebar_flagged red black
          color sidebar_new green black
          color error red default
          color tilde black default
          color message cyan default
          color markers red white
          color attachment white default
          color search brightmagenta default
          color status brightyellow black
          color hdrdefault brightgreen default
          color quoted green default
          color quoted1 blue default
          color quoted2 cyan default
          color quoted3 yellow default
          color quoted4 red default
          color quoted5 brightred default
          color signature brightgreen default
          color bold black default
          color underline black default
          # Regex highlighting:
          color header brightmagenta default "^From"
          color header brightcyan default "^Subject"
          color header brightwhite default "^(CC|BCC)"
          color header blue default ".*"
          color body brightred default "[\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+" # Email addresses
          color body brightblue default "(https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+" # URL
          color body green default "\`[^\`]*\`" # Green text between ` and `
          color body brightblue default "^# \.*" # Headings as bold blue
          color body brightcyan default "^## \.*" # Subheadings as bold cyan
          color body brightgreen default "^### \.*" # Subsubheadings as bold green
          color body yellow default "^(\t| )*(-|\\*) \.*" # List items as yellow
          color body brightcyan default "[;:][-o][)/(|]" # emoticons
          color body brightcyan default "[;:][)(|]" # emoticons
          color body brightcyan default "[ ][*][^*]*[*][ ]?" # more emoticon?
          color body brightcyan default "[ ]?[*][^*]*[*][ ]" # more emoticon?
          color body red default "(BAD signature)"
          color body cyan default "(Good signature)"
          color body brightblack default "^gpg: Good signature .*"
          color body brightyellow default "^gpg: "
          color body brightyellow red "^gpg: BAD signature from.*"
          mono body bold "^gpg: Good signature"
          mono body bold "^gpg: BAD signature from.*"
          color body red default "([a-z][a-z0-9+-]*://(((([a-z0-9_.!~*'();:&=+$,-]|%[0-9a-f][0-9a-f])*@)?((([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?|[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?)|([a-z0-9_.!~*'()$,;:@&=+-]|%[0-9a-f][0-9a-f])+)(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?(#([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?|(www|ftp)\\.(([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?(:[0-9]+)?(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?(#([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?)[^].,:;!)? \t\r\n<>\"]"
        '';
      };
    };
  };
}
