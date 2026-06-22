# dmgbuild settings for Sky. Builds the .dmg deterministically (no Finder/AppleScript).
# Invoked by scripts/build-dmg.sh which passes APP_PATH and VOLUME_NAME via env.
import os

app_path = os.environ["SKY_APP_PATH"]
app_name = os.path.basename(app_path)

# Files shown in the DMG window: the app + an Applications symlink.
files = [app_path]
symlinks = {"Applications": "/Applications"}

# Window geometry. Must match the background image's point dimensions (540x380).
# dmgbuild y-axis runs bottom-to-top for window_rect; icon_locations use the
# icon-view coordinate space (top-left origin), matching the window size.
window_rect = ((200, 200), (540, 380))
icon_size = 80
text_size = 12

icon_locations = {
    app_name: (140, 200),
    "Applications": (400, 200),
}

# Multi-resolution Retina TIFF (540x380 @1x + 1080x760 @2x).
background = os.environ["SKY_BACKGROUND"]

# Compressed read-only image.
format = "UDZO"

# No `icon`/`badge_icon` set on purpose → no .VolumeIcon.icns is created;
# the DMG uses the default macOS volume icon.
