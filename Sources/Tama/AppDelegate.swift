import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  let model = AppModel()

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApplication.shared.setActivationPolicy(.accessory)
    model.start()
  }

  func applicationWillTerminate(_ notification: Notification) {
    model.stop()
  }
}
