#!/usr/bin/env python3
# A window that opens a modal child dialog after a few seconds, like an app
# opening a file picker. Prints "cancel clicked" when the dialog's button is hit.
# With --standalone it shows only the dialog, as its own app with no parent,
# like a popup from another program; with --parent-only only the parent.
import sys
import gi
gi.require_version("Gtk", "4.0")
from gi.repository import GLib, Gtk

app = Gtk.Application(application_id="org.omarchy.macos.dialogtest" + ("2" if "--standalone" in sys.argv else ""))

MODE = sys.argv[2] if len(sys.argv) > 2 else ""

def activate(app):
    parent = Gtk.ApplicationWindow(application=app, title="Parent")
    parent.set_default_size(700, 500)
    if MODE != "--standalone":
        parent.present()
    if MODE == "--parent-only":
        return

    def open_dialog():
        if MODE == "--standalone":
            dialog = Gtk.ApplicationWindow(application=app, title="Dialog")
        else:
            dialog = Gtk.Window(title="Dialog", transient_for=parent, modal=True)
        dialog.set_default_size(320, 180)
        button = Gtk.Button(label="Cancel")
        def clicked(_):
            print("cancel clicked", flush=True)
            dialog.close()
        button.connect("clicked", clicked)
        dialog.set_child(button)
        dialog.present()
        print("dialog open", flush=True)
        return False

    GLib.timeout_add(int(sys.argv[1]) if len(sys.argv) > 1 else 4000, open_dialog)

app.connect("activate", activate)
app.run([])
