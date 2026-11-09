-- macOS trackpad gestures for Omarchy.
-- https://github.com/AfshinJalili/omarchy-macos-gestures
--
-- Installed by install.sh as ~/.config/hypr/macos/gestures.lua and loaded from
-- ~/.config/hypr/macos.lua with require("hypr.macos.gestures").

-- macOS: Accessibility > Pointer Control > Trackpad Options > Dragging style.
-- Turning on three-finger drag moves every swipe below to four fingers, as it
-- does on macOS, because libinput gives three-finger movement to the drag.
local THREE_FINGER_DRAG = false

local SWIPE = THREE_FINGER_DRAG and 4 or 3

hl.config({ input = { touchpad = { drag_3fg = THREE_FINGER_DRAG and 1 or 0 } } })

local function run(command)
  return function()
    hl.dispatch(hl.dsp.exec_cmd(command))
  end
end

-- Mission Control comes from the gloview plugin (hypr.macos.gloview). Looked up
-- when the swipe ends, so the gesture does nothing while gloview isn't loaded.
-- open and close are safe to repeat, so the swipe needn't know if it is open.
local function mission_control(action)
  return function()
    local gloview = hl.plugin.gloview
    if gloview and gloview[action] then
      gloview[action]()
    end
  end
end

-- Show Desktop: go to an empty workspace on this monitor, and back again.
-- Omarchy numbers each monitor's workspaces in its own block (o.workspaces), so
-- the empty one is looked for in that block, not Hyprland's lowest free number.
local SLOTS = 9
local desktop_return = nil

local function empty_slot(monitor)
  for slot = 1, SLOTS do
    local workspace = hl.get_workspace(o.workspaces.workspace_id(monitor, slot))
    if not workspace or (workspace.windows or 0) == 0 then
      return slot
    end
  end
end

local function show_desktop()
  local current = hl.get_active_workspace()
  if desktop_return and current and (current.windows or 0) == 0 then
    hl.dispatch(hl.dsp.focus({ workspace = tostring(desktop_return) }))
    desktop_return = nil
    return
  end

  local slot = empty_slot(hl.get_active_monitor())
  if not slot then
    return
  end
  desktop_return = current and current.id
  o.workspaces.focus(slot)()
end

-- Swipe left/right: move between workspaces (Spaces), following the fingers.
hl.gesture({ fingers = SWIPE, direction = "horizontal", action = "workspace" })

-- Swipe up: Mission Control. Swipe down, Esc or a click closes it.
hl.gesture({ fingers = SWIPE, direction = "up", action = mission_control("open") })
hl.gesture({ fingers = SWIPE, direction = "down", action = mission_control("close") })

-- Pinch with thumb and three fingers: Launchpad.
hl.gesture({ fingers = 4, direction = "pinchin", action = run("omarchy-menu toggle apps") })

-- Spread thumb and three fingers: Show Desktop; spread again to come back.
hl.gesture({ fingers = 4, direction = "pinchout", action = show_desktop })
