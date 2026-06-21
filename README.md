# dotfiles

Hyprland Wayland rice with a custom [Quickshell](https://quickshell.outfoxxed.me/) desktop shell, [Matugen](https://github.com/inflexion13/matugen)-driven Material Design 3 theming, and a curated set of application configs.

## Stack

- **Compositor**: Hyprland (Lua config)
- **Desktop Shell**: Quickshell (QML)
- **Theming**: Matugen (Material You dynamic colors)
- **Terminal**: Kitty
- **Music**: MPD + ncmpcpp
- **Qt Theming**: Qt6ct with Fusion style
- **Screenshot**: grim + slurp

## Repository Structure

```
.
├── bin/                          Custom scripts
│   ├── screenshot                Region capture via grim+slurp
│   ├── updatempd                 Batch tag MP3s + mpc update
│   └── ytrip                     YouTube audio downloader (yt-dlp)
├── config/
│   ├── hypr/                     Hyprland config + hyprlock
│   ├── kitty/                    Terminal config
│   ├── mpd/                      Music Player Daemon
│   ├── ncmpcpp/                  NCurses MPD client
│   ├── qt6/                      Qt6 global settings
│   ├── qt6ct/                    Qt6ct style + color palette
│   ├── quickshell/               Custom desktop shell (QML)
│   ├── scripts/                  Color generation scripts
│   │   ├── generate_colors.py    Matugen color pipeline entrypoint
│   │   ├── switch_wallpaper.py   Wallpaper switcher with color regen
│   │   └── templates/            GTK CSS templates (Jinja2)
│   └── home/                     Shell config (deploy to ~/)
│       ├── .zshrc                Zsh config (oh-my-zsh + p10k)
│       ├── .p10k.zsh             Powerlevel10k prompt config
│       ├── .fzf.zsh              Fzf integration
│       └── .oh-my-zsh/           Oh-my-zsh + plugins + themes
├── guidelines.txt                Architectural rules for the shell
├── LICENSE                       MIT
└── README.md
```

## Quickshell Desktop Shell

A modular, Material Design 3 desktop shell built in QML. All colors are sourced from Matugen's `~/.theme.json`, providing live dynamic theming.

### Design Tokens

Global constants defined in `shell.qml` — the single source of truth for all styling.

| Category | Tokens |
|---|---|
| **Spacing** | none (0), xs (4), sm (8), md (16), lg (24), xl (32), 2xl (48) |
| **Border Radius** | none (0), sm (4), md (12), lg (16), full (999) |
| **Typography** | Font: Roboto. Sizes: display (45pt), headline (24pt), body (12pt), icon (10pt), icon_large (20pt bold) |
| **Motion** | Durations: short (150ms), medium (250ms), long (400ms). Curves: standard, emphasis, subtle, linear, express |

### Modules

| Module | Purpose |
|---|---|
| **Bar** | Top panel — workspaces, media controls, battery, clock, system resource pies |
| **Sidebar** | Slide-in panel — WiFi/BT toggle, volume/brightness sliders, notification center, power actions |
| **Launcher** | App search with fuzzy matching, built-in calculator, DuckDuckGo web search |
| **OSD** | On-screen display for volume/brightness changes |
| **Notifications** | Popup stack with auto-dismiss, hover-to-pause, notification history |
| **PowerMenu** | Full-screen overlay — Lock, Suspend, Logout, Reboot, Shutdown with keyboard nav |
| **Screenshot** | Region/window/fullscreen capture via grim+slurp with copy/save preview |

### Services

Singletons that expose variables and functions. No UI — pure logic.

| Service | Purpose |
|---|---|
| MatugenService | Reads `~/.theme.json`, exposes 50+ MD3 color tokens, watches for live changes |
| AudioService | PipeWire volume control, mute toggle, up to 150% |
| BatteryService | UPower integration, percentage, charging state, low battery detection |
| BrightService | Backlight brightness via sysfs + brightnessctl |
| MprisService | MPRIS player tracking, position polling, auto-selects active player |
| NotificationService | Full notification server — actions, body markup, images, history |
| LauncherService | Fuzzy app matching, calculator, web search |
| CalculatorService | Recursive descent math parser (+−×÷, parentheses) |
| ScreenshotService | Capture lifecycle, clipboard copy, timestamped saves |
| SystemResourceService | Reads /proc/stat, /proc/meminfo, df every 1500ms |
| IconService | Icon resolution across themes (yamis, Adwaita, hicolor) with caching |
| EventBus | Signal bus for cross-module communication (sidebar/launcher toggles) |

### Components

Reusable, dumb UI primitives styled only with design tokens.

| Component | Description |
|---|---|
| Pill | Rounded rectangle container with background color |
| IconText | Text using MaterialSymbols icon font (small/large) |
| ProgressBar | Animated bar with configurable track/fill colors |
| PieChart | Canvas-drawn circular progress indicator |
| SystemResourcePie | PieChart + IconText + percentage label for system metrics |
| SidebarToggle | Toggle button with icon + On/Off text, animated color transition |
| SidebarSlider | Slider with icon label and numeric value |
| NotificationCard | Rich notification with icon, image, actions, swipe-to-dismiss |
| ScreenshotPreview | Post-capture card with thumbnail, copy/save buttons, auto-dismiss |

### Architecture

```
Design Tokens (colors, spacing, typography, motion)
       ↓
Components (Pill, PieChart, NotificationCard, ...)
       ↓
Modules (Bar, Sidebar, Launcher, ...)
       ↓
Services (Audio, Battery, Matugen, ...)
```

## Architectural Principles

Derived from `guidelines.txt` — the rules this shell follows:

- **No upward dependencies** — Modules depend on Components and Services. Components depend on Design Tokens. Nothing depends upward.
- **Module isolation** — Each module is removable without breaking the rest. Removing Launcher doesn't break Bar.
- **Modules don't couple** — Cross-module communication goes through shared state, the EventBus, or system signals. Never direct calls.
- **Components are dumb** — No system state, no workspace logic, no session logic. They display, accept input, or structure layout. Not multiple.
- **Token-only styling** — All visual values come from design tokens. No hardcoded magic numbers in components or modules.
- **Single responsibility** — Each module does one job. Bar shows state. Launcher searches apps. Notifications manage the queue. No feature creep.
- **State locality** — State lives in the smallest possible scope. Component state is local. Module state is module-only. Global state is shared system info only.

## Keybindings

Super (CapsLock remapped) is the main modifier.

| Key | Action |
|---|---|
| `Return` | Terminal (kitty) |
| `Q` | Close window |
| `D` | App launcher |
| `A` | Sidebar |
| `M` | Power menu |
| `E` | File manager (dolphin) |
| `V` | Toggle float |
| `P` | Pseudo-tiling |
| `J` | Toggle split |
| `Tab` | Cycle layout (master → dwindle → scrolling) |
| `S` | Toggle special workspace |
| `Shift+S` | Move window to special workspace |
| `0-9` | Switch workspace |
| `Shift+0-9` | Move window to workspace |
| Arrow keys | Focus direction |
| `Shift+Arrow` | Move window direction |
| `Print` | Screenshot |
| `XF86Audio*` | Volume +/−/mute, mic mute, media controls |
| `XF86MonBrightness*` | Brightness +/− |

## Scripts

| Script | Description |
|---|---|
| `bin/screenshot` | Region capture with grim+slurp, saves to `~/Pictures/Screenshots/` with notification |
| `bin/updatempd` | Batch retags MP3s using eyeD3 (title/artist from filename) then runs `mpc update` |
| `bin/ytrip` | YouTube audio downloader — `ytrip search "<query>"` or `ytrip download <url>`, outputs MP3 to `~/Music` |
| `config/scripts/generate_colors.py` | Matugen color pipeline — generates GTK, Kitty, Qt6ct, and Mako color configs from wallpaper |
| `config/scripts/switch_wallpaper.py` | Wallpaper switcher that triggers color regeneration |

## Shell Setup

Zsh configuration lives in `config/home/` and deploys to `~/`:

- **Oh-My-Zsh** with Powerlevel10k theme
- **Plugins**: git, sudo, colored-man-pages, fzf, zsh-autosuggestions, zsh-syntax-highlighting
- **Editor**: vim
- **Fzf** integration via `.fzf.zsh`

## License

[MIT](LICENSE)
