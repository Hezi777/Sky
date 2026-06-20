import os.path

# Injected via dmgbuild -D
application = defines["app"]
background = defines["background"]
appname = os.path.basename(application)

# Disk image. APFS + dmgbuild writes a `pBBk` bookmark into .DS_Store, which is
# the only background reference Finder reliably resolves on macOS 26 (Tahoe).
# create-dmg's AppleScript path silently fails to write this on Tahoe.
format = "UDZO"
filesystem = "APFS"

# Contents
files = [application]
symlinks = {"Applications": "/Applications"}
hide_extensions = [appname]

# Window / icon layout
icon_size = 88
text_size = 12
window_rect = ((100, 100), (540, 380))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
arrange_by = None
icon_locations = {
    appname: (165, 205),
    "Applications": (395, 205),
}
