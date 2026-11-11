#!/usr/bin/env python3
# A 26px panel along the top of the screen that reserves its space, like
# Omarchy's top bar. Run with LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so.
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, Gtk4LayerShell as LayerShell


def activate(app):
    panel = Gtk.Window(application=app)
    LayerShell.init_for_window(panel)
    LayerShell.set_layer(panel, LayerShell.Layer.TOP)
    for edge in (LayerShell.Edge.TOP, LayerShell.Edge.LEFT, LayerShell.Edge.RIGHT):
        LayerShell.set_anchor(panel, edge, True)
    panel.set_default_size(100, 26)
    LayerShell.auto_exclusive_zone_enable(panel)
    panel.set_child(Gtk.Label(label="top bar"))
    panel.present()


app = Gtk.Application(application_id="org.omarchy.macos.topbar")
app.connect("activate", activate)
app.run()
