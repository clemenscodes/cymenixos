# W3Champions / Warcraft III — Hyprland setup

## Window rules

| Window             | Workspace | Mode                                 |
| ------------------ | --------- | ------------------------------------ |
| `warcraft iii.exe` | 3         | fullscreen, immediate rendering      |
| `w3champions.exe`  | 2         | floating, centered, 80% monitor size |
| `battle.net.exe`   | —         | tiled, game content hint             |

## Lifecycle hooks (hyprhook, `amaru/configuration.nix`)

| Event   | Script             | Actions                                                |
| ------- | ------------------ | ------------------------------------------------------ |
| open    | `warcraft-open`    | WC3 wootswitch\*, gamemode on, headphones, launch OBS  |
| focus   | `warcraft-focus`   | WC3 wootswitch\*, enter `WARCRAFT` submap              |
| unfocus | `warcraft-unfocus` | Coding wootswitch\*, exit to default submap            |
| close   | `warcraft-close`   | Coding wootswitch\*, close OBS, gamemode off, speakers |

\* conditional on `modules.io.wooting.wootswitch.enable`; WC3 profile must exist in Wootility

## Keybinds (W3ChampionsOnLinux module)

### Global

| Bind       | Action                  |
| ---------- | ----------------------- |
| `Ctrl + W` | Enter `WARCRAFT` submap |

### `WARCRAFT` submap

| Bind                           | Action                         |
| ------------------------------ | ------------------------------ |
| `Alt + W`                      | Exit submap                    |
| `1` – `5`                      | Write control group 1–5        |
| `$mod + 1` – `$mod + 5`        | Write control group 6–10       |
| `Shift + mouse forward`        | Set selection as control group |
| `Shift + mouse back`           | Back to base                   |
| `$mod + Q / A / Y`             | Select hero 1 / 2 / 3          |
| `$mod + W / E / S / D / X / C` | Select item 1–6                |
| `Enter`                        | Open chat                      |
| `Space`                        | Enter `SELECT` submap          |

### `SELECT` submap

| Bind                              | Action                               |
| --------------------------------- | ------------------------------------ |
| `Q / W / E / R / T / mouse fwd`   | Select unit 1–6, return to WARCRAFT  |
| `A / S / D / F / G / mouse back`  | Select unit 7–12, return to WARCRAFT |
| `Shift + Q/W/E/R/A/S/D/F/Y/X/C/V` | Autocast ability, return to WARCRAFT |
| anything else                     | Return to WARCRAFT                   |

### `CHAT` submap

| Bind    | Action       |
| ------- | ------------ |
| `Enter` | Send message |
| `Esc`   | Close chat   |
