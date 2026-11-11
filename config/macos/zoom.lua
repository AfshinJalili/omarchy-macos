-- A zoomed (maximized) window that goes full screen comes back zoomed, as on
-- macOS. Hyprland brings back only a zoom the app asked for itself; one made
-- with the zoom light, a double-click on the titlebar or Super + Alt + F is
-- dropped, and the window returns to its old size.
--
-- The fullscreen event fires once the mode has changed, so each window's last
-- mode is kept to tell what it was before. Going from zoomed to full screen
-- fires twice in one go, zoomed to none and then none to full screen, so a
-- window leaving zoom is marked until the event loop comes round.
--
-- Hyprland clears event handlers on every reload but keeps the Lua state, so
-- the memory lives in a global and survives the reload, and the handlers are
-- registered again on each pass.

local NONE, MAXIMIZED, FULLSCREEN = 0, 1, 2

local memory = _G.__macos_zoom or { mode = {}, zoomed = {}, leaving = {} }
_G.__macos_zoom = memory

-- Windows that were already open before this pass.
for _, window in ipairs(hl.get_windows()) do
  memory.mode[window.address] = memory.mode[window.address] or (window.fullscreen or NONE)
end

local function after_this_event(fn)
  hl.timer(fn, { type = "oneshot", timeout = 1 })
end

hl.on("window.fullscreen", function(window)
  local address = window.address
  local before = memory.mode[address] or NONE
  local now = window.fullscreen or NONE
  memory.mode[address] = now

  if now == FULLSCREEN then
    if memory.leaving[address] then
      memory.zoomed[address] = true
    end
  elseif now == NONE and before == MAXIMIZED then
    memory.leaving[address] = true
    after_this_event(function()
      memory.leaving[address] = nil
    end)
  elseif now == NONE and before == FULLSCREEN and memory.zoomed[address] then
    memory.zoomed[address] = nil
    -- The event fires partway through leaving full screen; zoom once it is out.
    after_this_event(function()
      hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set", window = "address:" .. address }))
    end)
  elseif now == MAXIMIZED then
    memory.zoomed[address] = nil
  end
end)

hl.on("window.close", function(window)
  memory.mode[window.address] = nil
  memory.zoomed[window.address] = nil
  memory.leaving[window.address] = nil
end)
