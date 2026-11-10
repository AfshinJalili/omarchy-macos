-- macOS features on Omarchy: true turns one on, false turns it off.
-- install.sh copies this file to ~/.config/hypr/macos/settings.lua; edit that
-- copy. Changes apply at the next reload (hyprctl reload) or login. A setting
-- missing from it takes its value from here.
return {
  -- Rounded corners, soft shadows, blur and thin borders.
  look = true,

  -- Windows zoom in softly and desktops slide sideways.
  motion = true,

  -- The WhiteSur cursor, when it is installed in ~/.local/share/icons.
  cursor = true,

  -- Super + Space searches apps, like Spotlight. The Omarchy menu moves to
  -- Super + Alt + Space.
  spotlight = true,

  -- Titlebars with traffic lights on floating workspaces.
  titlebars = true,

  -- Mission Control: swipe up with three fingers, or press Ctrl + Up.
  mission_control = true,

  -- Trackpad gestures: swipe between desktops, Mission Control, Launchpad and
  -- Show Desktop.
  gestures = true,

  -- macOS's three-finger drag: drag windows and text with three fingers, and
  -- every swipe above moves to four.
  three_finger_drag = false,
}
