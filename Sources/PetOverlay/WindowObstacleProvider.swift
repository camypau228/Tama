import AppKit
import CoreGraphics

@MainActor
protocol WindowObstacleProviding {
  func visibleWindowFrames() -> [CGRect]?
}

@MainActor
struct WindowObstacleProvider: WindowObstacleProviding {
  func visibleWindowFrames() -> [CGRect]? {
    guard
      let windowInfo = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements],
        CGWindowID(kCGNullWindowID)
      ) as? [[String: Any]],
      let primaryScreenHeight = NSScreen.screens.first?.frame.height
    else {
      return nil
    }

    let currentProcessID = ProcessInfo.processInfo.processIdentifier

    return windowInfo.compactMap { window in
      guard
        (window[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
        (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value != currentProcessID,
        ((window[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1) > 0.01,
        let boundsDictionary = window[kCGWindowBounds as String] as? [String: Any],
        let quartzFrame = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary)
      else {
        return nil
      }

      return CGRect(
        x: quartzFrame.minX,
        y: primaryScreenHeight - quartzFrame.maxY,
        width: quartzFrame.width,
        height: quartzFrame.height
      )
    }
  }
}
