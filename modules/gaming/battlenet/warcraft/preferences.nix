{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming.battlenet;
  inherit (config.modules.users) name;
in {
  config = lib.mkIf (cfg.enable && cfg.warcraft.enable) {
    environment = {
      systemPackages = [inputs.battlenet.packages.${system}.battlenet];
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          users = {
            ${config.modules.users.name} = {
              directories = [
                ".local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/"
                ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms"
              ];
            };
          };
        };
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${name} = {
          home = {
            file = {
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/mainmenu.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/corner-machinery-animated.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/random-bg.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/roc_prologue.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/roc_human.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/roc_orc.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/roc_nightelf.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/roc_undead.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/tft_human.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/tft_orc.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/tft_nightelf.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/Program Files (x86)/Warcraft III/_retail_/webui/webms/tft_undead.webm" = {
                text = "";
              };
              ".local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/War3Preferences.txt" = {
                text = ''
                  [Commandbar Hotkeys 00]
                  HeroOnly=0
                  Hotkey=81
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 01]
                  HeroOnly=0
                  Hotkey=87
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 02]
                  HeroOnly=0
                  Hotkey=69
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 03]
                  HeroOnly=0
                  Hotkey=82
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 10]
                  HeroOnly=0
                  Hotkey=65
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 11]
                  HeroOnly=0
                  Hotkey=83
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 12]
                  HeroOnly=0
                  Hotkey=68
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 13]
                  HeroOnly=0
                  Hotkey=70
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 20]
                  HeroOnly=0
                  Hotkey=90
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 21]
                  HeroOnly=0
                  Hotkey=88
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 22]
                  HeroOnly=0
                  Hotkey=67
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 23]
                  HeroOnly=0
                  Hotkey=86
                  MetaKeyState=0
                  QuickCast=0

                  [Custom Hotkeys 0]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 1]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 2]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 3]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 4]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 5]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 6]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 7]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Gameplay]
                  allyFilter=1
                  ammmaphashes=
                  ammmapprefs=
                  ammrace=32
                  ammstyles=
                  ammtype=0
                  autosaveReplay=1
                  bgMenuMovie=2
                  cinePortraits=1
                  classicCursor=0
                  coloredhealthbars=1
                  commandbuttonhotkey=1
                  creepFilter=1
                  customfilter=0
                  custommask=0
                  defaultZoom=3000
                  denyIcon=1
                  displayapm=1
                  displayfps=1
                  displayping=1
                  enabledAdvancedObserverUi=false
                  enabledEnhancedZoom=1
                  enabledGameInfoMessages=1
                  enabledGlobalChat=1
                  enabledObserverChat=true
                  enabledOpponentChat=1
                  enabledTeamChat=true
                  formations=0
                  formationtoggle=1
                  gamespeed=2
                  goldmineUnitCounter=1
                  healthbars=1
                  herobar=1
                  heroframes=1
                  herolevel=1
                  hudscale=100
                  hudsidepanels=1
                  maxZoom=3000
                  multiboardon=1
                  netgameport=6112
                  numericCooldown=1
                  occlusion=0
                  peonDoubleTapFocus=1
                  profanity=0
                  schedrace=32
                  showtimeelapsed=1
                  subgrouporder=1
                  teen=0
                  terrainFilter=1
                  tooltips=1
                  useSkins=1

                  [Input]
                  confinemousecursor=1
                  customkeys=1
                  keyscroll=50
                  mousescroll=50
                  mousescrolldisable=0
                  reducemouselag=1

                  [Inventory Hotkeys 0]
                  HeroOnly=0
                  Hotkey=84
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 1]
                  HeroOnly=0
                  Hotkey=89
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 2]
                  HeroOnly=0
                  Hotkey=71
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 3]
                  HeroOnly=0
                  Hotkey=72
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 4]
                  HeroOnly=0
                  Hotkey=66
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 5]
                  HeroOnly=0
                  Hotkey=78
                  MetaKeyState=0
                  QuickCast=0

                  [Map]
                  battlenet_V0=
                  battlenet_V1=
                  lan_V0=
                  lan_V1=
                  skirmish_V0=
                  skirmish_V1=

                  [Misc]
                  bnetGateway=
                  chatsupport=0
                  clickedad=0
                  clickedclan=0
                  clickedladder=0
                  clickedtourn=0
                  hd=0
                  lastseasonseen=0
                  legacylinkreminder=1
                  offlineavatar=p068
                  regioncomplianceaccepted=0
                  seenintromovie=1
                  settingsversion=3
                  versusUnrankedPreferred=0

                  [Mouse Mid Button Down]
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Mouse Wheel Down]
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Mouse Wheel Up]
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Reforged]
                  Buildings=1
                  Environment=1
                  EnvOld=0
                  Heroes=1
                  Icons=1
                  Textures=1
                  Units=1
                  Vfx=1

                  [Sound]
                  ambient=1
                  assetmode=0
                  classicsound=1
                  donotusewaveout=0
                  environmental=1
                  movement=1
                  music=1
                  musicoverride=
                  musicvolume=30
                  nosoundwarn=1
                  outputsounddev=0
                  outputspeakermode=-1
                  positional=1
                  sfx=1
                  sfxvolume=50
                  subtitles=1
                  unit=1
                  windowfocus=1

                  [String]
                  gamemodePreferred=1v1
                  userbnet=
                  userlocal=

                  [Video]
                  adapter=0
                  antialiasing=1
                  backgroundmaxfps=10
                  colordepth=32
                  foliagequality=3
                  gamma=30
                  lightingquality=2
                  maxfps=300
                  particles=2
                  previouswindowmode=0
                  refreshrate=240
                  resetdefaults=0
                  resheight=1080
                  reswidth=1920
                  shadowquality=3
                  spellfilter=2
                  texquality=2
                  vsync=0
                  windowheight=810
                  windowmode=2
                  windowwidth=1440
                  windowx=240
                  windowy=135
                '';
              };
            };
          };
        };
      };
    };
  };
}
