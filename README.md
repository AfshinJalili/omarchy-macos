# omarchy-macos

macOS on [Omarchy](https://omarchy.org): titlebars with traffic lights, Mission Control, trackpad gestures, rounded windows with soft shadows, macOS motion, Spotlight on Super + Space and the macOS cursor. One install, and every feature switches on or off in one settings file.

## Features

| Setting | What it does |
|---|---|
| `look` | Rounded corners, soft shadows, blur and thin borders, and frosted glass behind Omarchy's menus and pop-ups |
| `motion` | Windows zoom in softly and desktops slide sideways |
| `cursor` | The WhiteSur cursor, when it is installed in `~/.local/share/icons` |
| `spotlight` | Super + Space searches apps. The Omarchy menu moves to Super + Alt + Space |
| `titlebars` | Titlebars with close, minimize and zoom lights on floating workspaces; a zoomed window that goes full screen comes back zoomed |
| `mission_control` | Mission Control: swipe up with three fingers, or Ctrl + Up |
| `gestures` | The trackpad gestures below |
| `three_finger_drag` | macOS's three-finger drag; the swipes move to four fingers |

| Gesture | Does |
|---|---|
| 3 fingers left / right | Switch desktops, following your fingers |
| 3 fingers up | Mission Control |
| 3 fingers down | Close Mission Control (Esc or a click on empty space also close it) |
| Pinch in, 4 fingers | Launchpad: [omacast](https://github.com/typecraft-dev/oma-cast) when it is installed, otherwise Omarchy's app launcher |
| Spread out, 4 fingers | Show Desktop: an empty desktop on this monitor. Spread again to come back |

In Mission Control, swipe left or right with three fingers, or scroll with two, to move between desktops; click a desktop in the strip to go to it.

Tap to click, two-finger right click and natural scrolling stay as Omarchy and your `input.lua` set them.

## Themes

Two Omarchy themes come with it, **Macos Light** and **Macos Dark**: macOS colours, the WhiteSur icons, and menus at 80% opacity so the frosted glass from `look` shows through. Pick one with `omarchy theme set "Macos Dark"` or Omarchy's theme menu.

They live in `themes/` and the installer links them into `~/.config/omarchy/themes/`, so this repository is the one copy. Edit them here, then run `omarchy theme set` again to apply the change.

### macOS wallpapers

Apple's wallpapers are Apple's, so the themes ship plain gradients and `scripts/wallpapers.sh` fetches the real ones on request: every recent default wallpaper from Big Sur to Tahoe (from [512 Pixels](https://512pixels.net/projects/default-mac-wallpapers-in-5k/)), and Apple's live aerial wallpapers from Sonoma and Sequoia.

```sh
scripts/wallpapers.sh                          # list them
scripts/wallpapers.sh tahoe-dark sonoma-horizon
scripts/wallpapers.sh --light tahoe-light      # for Macos Light
omarchy theme bg set ~/.config/omarchy/backgrounds/macos-dark/sonoma-horizon.mp4
```

They are saved to `~/.config/omarchy/backgrounds/macos-dark/` (or `macos-light/`), where Omarchy's background switcher lists them with the theme's own. A live wallpaper is a 600 MB 4K download, converted once with `ffmpeg` to 1440p at 60 fps so it plays lightly behind the desktop.

## Install

Needs Omarchy with the Lua config, on Hyprland 0.56 or 0.57, and `cmake`, `git`, `jq` and `pkg-config`.

```sh
git clone https://github.com/AfshinJalili/omarchy-macos ~/Projects/omarchy-macos
~/Projects/omarchy-macos/install.sh
```

The installer:

- builds the two plugins for the Hyprland you have, into `~/.local/lib/omarchy-macos/`;
- links `~/.config/hypr/macos.lua` and the modules in `~/.config/hypr/macos/` to this repository, so a `git pull` and a reload update them;
- creates `~/.config/hypr/macos/settings.lua` with every feature on, unless you have one;
- adds `require("hypr.macos")` to `~/.config/hypr/hyprland.lua`;
- links the two themes into `~/.config/omarchy/themes/`;
- installs a pacman hook that rebuilds the plugins after each Hyprland upgrade (skip it with `--no-hook`);
- moves any file or theme it replaces to `~/.config/hypr/macos/backup-<time>/`.

`./uninstall.sh` removes it again and leaves your `settings.lua`.

## Settings

Edit `~/.config/hypr/macos/settings.lua`, then run `hyprctl reload`:

```lua
return {
  mission_control = true,
  three_finger_drag = false,
  look = false, -- keep Omarchy's own look
}
```

A setting you leave out takes its default from `config/macos/defaults.lua`.

## How it fits together

- `config/macos.lua` loads one module per enabled feature from `config/macos/`.
- `plugins/titlebars` is the titlebar plugin, a fork of Omarchy's titlebars and hyprbars. It takes the place of Omarchy's titlebar plugin when it loads, and Omarchy's comes back if it doesn't. See [its README](plugins/titlebars/README.md).
- `plugins/mission-control` is Mission Control, a hard fork of [gloview](https://github.com/fedsfarm/gloview). See [its README](plugins/mission-control/README.md) for its options.
- A plugin only loads into the Hyprland it was built for. `scripts/build-plugins.sh` builds both for the installed Hyprland from the sources `hyprpm.toml` pins for it: branch `main` targets Hyprland 0.57, and `hyprland-0.56` holds the plugins for 0.56. The pacman hook runs it after Hyprland upgrades; the build log is in `~/.cache/omarchy-macos/build.log`.

## Not possible on Linux

Notification Center (a swipe from the right edge), Force Touch / Look Up and smart zoom need Apple's trackpad hardware or drivers. Linux touchpads don't report edge swipes or pressure.

## License

The config and scripts are MIT (`LICENSE`). The titlebar plugin is BSD-3-Clause and MIT (`plugins/titlebars/LICENSE`, `LICENSE.MIT`); Mission Control is GPLv3 (`plugins/mission-control/LICENSE`).
