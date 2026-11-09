# hyprbars-macos

macOS-style title bars for [Hyprland](https://hyprland.org): traffic lights on the left, a centered title, and the small details that make them feel native.

![Focused window with the lights hovered, above an unfocused window](docs/screenshot.png)

| Resting | Hovered |
| --- | --- |
| ![Lights at rest](docs/lights-plain.png) | ![Lights with their glyphs](docs/lights.png) |

## What it does

- **Traffic lights drawn properly.** Each light is an anti-aliased circle with a faint rim, rendered at the exact pixel size of the monitor it is on, so it stays round and smooth at 1x, 1.5x, or 2x.
- **macOS glyphs.** Close (×), minimize (−), and full screen (two triangles) are drawn as vector shapes, not text. Hovering any light shows all three, as on macOS.
- **Unfocused windows.** Lights turn grey and the title dims.
- **Monitors with different scales.** The title keeps its size when a window moves between monitors with different scales, including mid-drag across both.
- **Bars stay during a swipe.** Hyprland drops the decorations of a maximized window while it slides past a workspace with a fullscreen window. The plugin turns them back on (`maximizedDecorations.cpp`).
- **Drop-in.** The plugin registers as `hyprbars` and keeps the `hl.plugin.hyprbars` Lua interface and `plugin.hyprbars.*` options, so configs written for hyprbars or Omarchy's titlebars keep working. Square buttons (`button_rounding` ≥ 0) still draw the classic way.

It is a fork of [Omarchy's titlebars](https://github.com/omacom/omarchy-hyprland-titlebars), itself a fork of [hyprbars](https://github.com/hyprwm/hyprland-plugins/tree/main/hyprbars). Dragging, double-click to maximize, the `%WINDOW%` placeholder, app-name titles, and `workspace_tag` all come from those.

## Install

With [hyprpm](https://wiki.hypr.land/Plugins/Using-Plugins/):

```bash
hyprpm update
hyprpm add https://github.com/AfshinJalili/hyprbars-macos
hyprpm enable hyprbars-macos
```

Have `hyprpm reload` run at startup so the plugin loads with each session:

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("hyprpm reload -n")
end)
```

Do not load it next to another `hyprbars` build; they share a name and options.

| Hyprland | Source |
| --- | --- |
| 0.57.x | `main` |
| 0.56.x | `hyprland-0.56` |

`hyprpm` picks the right one for your Hyprland through the pins in `hyprpm.toml`.

Releases are tagged `vX.Y.Z`. Each Hyprland version a commit was tested against also gets an `hlX.Y.Z` tag on that commit, for packagers and manual builds.

## Configure

The plugin reloads the config once it has loaded, so guard the configuration on it being there. A macOS setup:

```lua
if hl.plugin.hyprbars then
  local window = [[window = "address:%WINDOW%"]]

  hl.config({
    plugin = {
      hyprbars = {
        enabled = true,
        bar_height = 28,
        bar_color = "rgb(323232)",
        col = { text = "rgb(e6e6e6)" },
        bar_text_font = "Inter",
        bar_text_size = 13,
        bar_text_weight = "semibold",
        bar_text_align = "center",
        bar_buttons_alignment = "left",
        bar_padding = 12,
        bar_button_padding = 8,
        button_rounding = -1, -- circles: draws traffic lights
        icon_on_hover = true, -- glyphs only while a light is hovered
        inactive_button_color = "rgba(80808066)",
        inactive_title_opacity = 50,
      },
    },
  })

  for _, light in ipairs({
    { "rgb(ff5f57)", "rgba(4d0000d9)", "close", "hyprctl dispatch 'hl.dsp.window.close({ " .. window .. " })'" },
    { "rgb(febc2e)", "rgba(985712d9)", "minimize", "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:minimized\", follow = false, " .. window .. " })'" },
    { "rgb(28c840)", "rgba(0a5d17d9)", "fullscreen", "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", " .. window .. " })'" },
  }) do
    hl.plugin.hyprbars.add_button({ bg_color = light[1], fg_color = light[2], size = 12, icon = light[3], action = light[4] })
  end
end
```

Buttons are added in order from the aligned edge, so with `bar_buttons_alignment = "left"` the first one is leftmost.

### Light glyphs

With `button_rounding = -1`, a button whose `icon` names a glyph is drawn as a traffic light with that glyph in its `fg_color`:

| `icon` | Glyph |
| --- | --- |
| `close` (or `×`, `x`) | × |
| `minimize` (or `−`, `-`) | − |
| `zoom` (or `+`) | + |
| `fullscreen` (or `maximize`, `□`, `⤢`) | two triangles |
| `""` | none, a plain light |

Any other icon is drawn as text, as in hyprbars.

### Options

All upstream [hyprbars options](https://github.com/hyprwm/hyprland-plugins/tree/main/hyprbars) apply. This fork and Omarchy's add:

| Option | Default | Behavior |
| --- | --- | --- |
| `enabled` | `false` | Upstream defaults to true. Off here, so a plugin left loaded after the config stops configuring it draws nothing. Set it to `true`. |
| `inactive_title_opacity` | `100` | Title opacity in percent while the window is unfocused. |
| `inactive_button_color` | `0` | When set, unfocused windows draw their buttons in this colour (grey lights). |
| `bar_color_inactive` | transparent | Inactive title bar colour; transparent falls back to `bar_color`. |
| `workspace_tag` | empty | When set, title bars apply only to floating windows with this tag. |

`%WINDOW%` in a button `action` or `on_double_click` is replaced with the clicked window's address, so an action keeps its target even if focus changes before it runs.

## With Omarchy

Omarchy loads its own titlebar plugin for floating workspaces from a fixed path. To use this one instead, wrap `hl.plugin.load` in a file your `hyprland.lua` requires before Omarchy's workspace modes run:

```lua
local OMARCHY = "/usr/lib/omarchy-hyprland-titlebars/titlebars.so"
local MACOS = os.getenv("HOME") .. "/.local/lib/hyprbars-macos/hyprbars-macos.so"

-- hyprbars-macos reports a version starting with "macos-".
local function macos_loaded()
  for _, plugin in ipairs(hl.get_loaded_plugins()) do
    if plugin.name == "hyprbars" and tostring(plugin.version):find("^macos%-") then
      return true
    end
  end
  return false
end

local load = hl.plugin.load
hl.plugin.load = function(path, ...)
  if path == OMARCHY then
    local ok = pcall(load, MACOS, ...)
    if ok and macos_loaded() then
      return
    end
  end
  return load(path, ...)
end
```

If the build does not match your Hyprland, Omarchy's plugin loads instead, so floating windows keep their title bars. Install a build there with `scripts/install-local.sh`.

The two plugins share the `plugin:hyprbars` options and `hl.plugin.hyprbars`. Hyprland gives each name to the plugin that registered it first and removes it when that plugin unloads. This wrapper loads this plugin while Omarchy's is still loaded, so this plugin registers the names it was refused again before each config reload and adds its own bar to windows that show Omarchy's; switching to it in a running session needs nothing else. Omarchy's plugin does not do this, so to switch back, unload this one first or switch in a fresh session.

## Build

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

`scripts/install-local.sh` builds, installs to `~/.local/lib/hyprbars-macos/`, and loads the new build into the running Hyprland. It replaces the file without overwriting it in place, which could crash a compositor that has it loaded.

### Rebuild on Hyprland updates

A plugin only loads into the Hyprland it was built for. On Arch, `scripts/install-pacman-hook.sh` installs a pacman hook that runs `scripts/rebuild-for-hyprland.sh` after every Hyprland install or upgrade. The script picks the plugin commit `hyprpm.toml` pins for the new Hyprland (or `main`), builds it, and installs it for the next login; the build log is in `~/.cache/hyprbars-macos/rebuild.log`. Remove the hook with `sudo rm /etc/pacman.d/hooks/hyprbars-macos.hook`.

## Test

The scripts in `test/` run a disposable nested Hyprland, so a broken build cannot take down your session:

- `test/run-nested.sh [scale] [out.png] [x,y]` screenshots a focused and an unfocused window, optionally hovering a point.
- `test/run-two-monitors.sh` moves a window from a 1x to a 2x monitor and screenshots its title on each.
- `test/run-swap.sh [reverse]` swaps between Omarchy's plugin and this one with a config reload, as the Omarchy wrapper does, and reports whether the options, `hl.plugin.hyprbars` and the open window's bar survive.
- `test/run-swipe.sh [out.png] [plugin.so]` screenshots a maximized window sliding past a fullscreen workspace, where its bar must stay.

`tools/verify.py` is upstream's verifier for dragging, maximize, and action targeting.

## Maintenance

- **Build** (`.github/workflows/build.yml`) compiles every push and pull request against the Hyprland release in `ci/hyprland-version`. `ci/hyprland-headers.sh` installs that release's headers with the exact hyprwm libraries its `flake.lock` pins, so the check does not depend on what Arch ships.
- **Hyprland release** (`.github/workflows/hyprland-release.yml`) runs daily. When Hyprland publishes a release `hyprpm.toml` does not pin, it builds `main` against it; on success it pins the release, tags the commit `hlX.Y.Z`, and moves `ci/hyprland-version`; on failure it opens an issue.
- When a Hyprland release changes the plugin API, port `main`, and keep the last working commit for the old version pinned in `hyprpm.toml`.
- `maximizedDecorations.cpp` hooks `IHyprRenderer::renderWindow`, which is outside the plugin API. A changed signature fails the build with a `static_assert`; a renamed function only logs a warning and loses the fix. Delete the file once Hyprland draws those windows with their own decorations.

## License

The original hyprbars code is under the BSD-3-Clause license in `LICENSE`. Omarchy's changes are under the MIT license in `LICENSE.MIT`, and this fork's changes are under the same MIT terms.
