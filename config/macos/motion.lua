-- Windows zoom in softly and desktops slide sideways.
hl.curve("macos", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "macos", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "macos", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "macos" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, bezier = "macos", style = "slide" })
