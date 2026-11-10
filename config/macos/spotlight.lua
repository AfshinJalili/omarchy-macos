-- Super + Space searches apps, like Spotlight. The Omarchy menu it opened
-- moves to Super + Alt + Space, in place of the app grid there.
o.rebind("SUPER + SPACE", "Search apps", { menu = "apps" })
o.rebind("SUPER + ALT + SPACE", "Omarchy menu", { menu = "root" })
