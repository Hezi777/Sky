// Prints the CGWindowID and size of the frontmost on-screen window belonging to
// a named app, so `screencapture -l <id>` can grab that window alone.
//
// Window capture (rather than a screen region) is what makes a full-dashboard
// shot possible: the capture reads the window's own backing store, so the part
// of a taller-than-display window that hangs off the screen is still included.
//
// Usage: swift window-id.swift Sky

import CoreGraphics
import Foundation

let appName = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Sky"

guard let windows = CGWindowListCopyWindowInfo(
    [.optionOnScreenOnly, .excludeDesktopElements],
    kCGNullWindowID
) as? [[String: Any]] else {
    FileHandle.standardError.write(Data("could not read window list\n".utf8))
    exit(1)
}

for window in windows {
    guard let owner = window[kCGWindowOwnerName as String] as? String, owner == appName,
          let id = window[kCGWindowNumber as String] as? Int,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? Double,
          let height = bounds["Height"] as? Double else { continue }

    // Skip incidental panels; the dashboard is the large one.
    if width < 400 || height < 400 { continue }

    print("\(id) \(Int(width)) \(Int(height))")
    exit(0)
}

FileHandle.standardError.write(Data("no window found for \(appName)\n".utf8))
exit(1)
