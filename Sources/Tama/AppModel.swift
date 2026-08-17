import AppKit
import PetOverlay
import SwiftUI
import TamaShared

@MainActor
final class AppModel: ObservableObject {
  let menuBarIcon: NSImage?

  @Published var isPetVisible: Bool {
    didSet {
      defaults.set(isPetVisible, forKey: Keys.petVisible)
      applyVisibility()
    }
  }

  @Published var isMovementPaused: Bool {
    didSet {
      defaults.set(isMovementPaused, forKey: Keys.movementPaused)
      overlay?.setMovementPaused(isMovementPaused)
    }
  }

  @Published var scale: PetScale {
    didSet {
      defaults.set(scale.rawValue, forKey: Keys.scale)
      overlay?.setScale(scale)
    }
  }

  @Published private(set) var startupError: String?

  private let defaults: UserDefaults
  private var overlay: PetWindowController?

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    menuBarIcon = (try? SpriteAtlas())?.menuBarIcon()
    isPetVisible = defaults.object(forKey: Keys.petVisible) as? Bool ?? true
    isMovementPaused = defaults.object(forKey: Keys.movementPaused) as? Bool ?? false
    scale = PetScale(rawValue: defaults.double(forKey: Keys.scale)) ?? .regular
  }

  var statusText: String {
    if startupError != nil { return "Не удалось показать питомца" }
    if !isPetVisible { return "Скрыт" }
    if isMovementPaused { return "Спокойно сидит" }
    return "Наблюдает за рабочим столом"
  }

  var movementBinding: Binding<Bool> {
    Binding(
      get: { !self.isMovementPaused },
      set: { self.isMovementPaused = !$0 }
    )
  }

  func start() {
    guard overlay == nil else { return }

    do {
      let overlay = try PetWindowController()
      self.overlay = overlay
      overlay.setScale(scale)
      overlay.setMovementPaused(isMovementPaused)
      applyVisibility()
    } catch {
      startupError = error.localizedDescription
    }
  }

  func stop() {
    overlay?.hide()
    overlay = nil
  }

  func quit() {
    stop()
    NSApplication.shared.terminate(nil)
  }

  private func applyVisibility() {
    guard let overlay else { return }
    isPetVisible ? overlay.show() : overlay.hide()
  }

  private enum Keys {
    static let petVisible = "pet.visible"
    static let movementPaused = "pet.movementPaused"
    static let scale = "pet.scale"
  }
}
