import AppKit
import PetOverlay
import SwiftUI

@main
struct TamaApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    MenuBarExtra {
      MenuBarPopover(model: appDelegate.model)
    } label: {
      if let icon = appDelegate.model.menuBarIcon {
        Image(nsImage: icon)
      } else {
        Image(systemName: "cat.fill")
      }
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView(model: appDelegate.model)
    }
  }
}
