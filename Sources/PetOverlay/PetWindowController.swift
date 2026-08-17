import AppKit
import TamaShared

@MainActor
public final class PetWindowController {
  private static let screenPadding: CGFloat = 24

  private let panel: PetPanel
  private let spriteView: SpriteAnimatorView
  private var globalMouseMonitor: Any?
  private var localMouseMonitor: Any?
  private var isMovementPaused = false

  public init() throws {
    let atlas = try SpriteAtlas()
    spriteView = SpriteAnimatorView(atlas: atlas)
    panel = PetPanel(
      contentRect: CGRect(
        x: 0,
        y: 0,
        width: SterlingAtlasLayout.cellWidth,
        height: SterlingAtlasLayout.cellHeight
      ),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    configurePanel()
    spriteView.onPetClick = { [weak self] in
      self?.playGreeting()
    }
    spriteView.onFrameChanged = { [weak self] in
      self?.updateMouseHitTesting(at: NSEvent.mouseLocation)
    }
  }

  public func show() {
    positionAtBottomRightOfActiveScreen()
    panel.orderFrontRegardless()
    startMouseObservation()
    applyMovementState()
    updateMouseHitTesting(at: NSEvent.mouseLocation)
  }

  public func hide() {
    stopMouseObservation()
    spriteView.stop()
    panel.ignoresMouseEvents = true
    panel.orderOut(nil)
  }

  public func setMovementPaused(_ isPaused: Bool) {
    isMovementPaused = isPaused
    applyMovementState()
  }

  public func setScale(_ scale: PetScale) {
    let size = CGSize(
      width: CGFloat(SterlingAtlasLayout.cellWidth) * CGFloat(scale.rawValue),
      height: CGFloat(SterlingAtlasLayout.cellHeight) * CGFloat(scale.rawValue)
    )
    panel.setContentSize(size)
    positionAtBottomRightOfActiveScreen()
    updateMouseHitTesting(at: NSEvent.mouseLocation)
  }

  public func playGreeting() {
    guard !isMovementPaused else { return }

    spriteView.play(.waving) { [weak self] in
      self?.applyMovementState()
    }
  }

  private func configurePanel() {
    panel.contentView = spriteView
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .stationary]
    panel.ignoresMouseEvents = true
    panel.acceptsMouseMovedEvents = true
  }

  private func applyMovementState() {
    guard panel.isVisible else { return }

    if isMovementPaused {
      spriteView.showStatic()
    } else {
      spriteView.play(.idle)
    }
  }

  private func positionAtBottomRightOfActiveScreen() {
    guard let screen = activeScreen else { return }

    let visibleFrame = screen.visibleFrame
    let origin = CGPoint(
      x: visibleFrame.maxX - panel.frame.width - Self.screenPadding,
      y: visibleFrame.minY + Self.screenPadding
    )
    panel.setFrameOrigin(origin)
  }

  private var activeScreen: NSScreen? {
    let pointer = NSEvent.mouseLocation
    return NSScreen.screens.first { $0.frame.contains(pointer) } ?? NSScreen.main
  }

  private func startMouseObservation() {
    guard globalMouseMonitor == nil, localMouseMonitor == nil else { return }

    globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
    ) { [weak self] _ in
      Task { @MainActor in
        self?.updateMouseHitTesting(at: NSEvent.mouseLocation)
      }
    }

    localMouseMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
    ) { [weak self] event in
      self?.updateMouseHitTesting(at: NSEvent.mouseLocation)
      return event
    }
  }

  private func stopMouseObservation() {
    if let globalMouseMonitor {
      NSEvent.removeMonitor(globalMouseMonitor)
      self.globalMouseMonitor = nil
    }
    if let localMouseMonitor {
      NSEvent.removeMonitor(localMouseMonitor)
      self.localMouseMonitor = nil
    }
  }

  private func updateMouseHitTesting(at screenPoint: CGPoint) {
    guard panel.isVisible, panel.frame.contains(screenPoint) else {
      panel.ignoresMouseEvents = true
      return
    }

    let windowPoint = panel.convertPoint(fromScreen: screenPoint)
    let viewPoint = spriteView.convert(windowPoint, from: nil)
    panel.ignoresMouseEvents = !spriteView.isVisible(at: viewPoint)
  }
}

@MainActor
private final class PetPanel: NSPanel {
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}
