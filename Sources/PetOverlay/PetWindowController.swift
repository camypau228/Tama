import AppKit
import QuartzCore
import TamaShared

@MainActor
public final class PetWindowController {
  private static let screenPadding: CGFloat = 24
  private static let roamingRestInterval: TimeInterval = 4
  private static let unavailableRetryInterval: TimeInterval = 5
  private static let roamingSpeed: CGFloat = 70

  private let panel: PetPanel
  private let spriteView: SpriteAnimatorView
  private let obstacleProvider: WindowObstacleProviding
  private var globalMouseMonitor: Any?
  private var localMouseMonitor: Any?
  private var roamingTimer: Timer?
  private var isMovementPaused = false
  private var isRequestedVisible = false
  private var prefersRight = true

  init(obstacleProvider: WindowObstacleProviding) throws {
    self.obstacleProvider = obstacleProvider
    let atlas = try SpriteAtlas()
    let displaySize = SterlingDisplayMetrics.size(for: .regular)
    spriteView = SpriteAnimatorView(atlas: atlas)
    panel = PetPanel(
      contentRect: CGRect(
        x: 0,
        y: 0,
        width: CGFloat(displaySize.width),
        height: CGFloat(displaySize.height)
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

  public convenience init() throws {
    try self.init(obstacleProvider: WindowObstacleProvider())
  }

  public func show() {
    isRequestedVisible = true
    evaluateRoaming()
  }

  public func hide() {
    isRequestedVisible = false
    stopRoamingTimer()
    stopMouseObservation()
    spriteView.stop()
    panel.ignoresMouseEvents = true
    panel.orderOut(nil)
  }

  public func setMovementPaused(_ isPaused: Bool) {
    isMovementPaused = isPaused
    stopRoamingTimer()
    evaluateRoaming()
  }

  public func setScale(_ scale: PetScale) {
    let displaySize = SterlingDisplayMetrics.size(for: scale)
    let size = CGSize(
      width: CGFloat(displaySize.width),
      height: CGFloat(displaySize.height)
    )
    setPanelSize(size)
    updateMouseHitTesting(at: NSEvent.mouseLocation)
    scheduleRoaming(after: 0.25)
  }

  public func playGreeting() {
    guard !isMovementPaused else { return }

    stopRoamingTimer()
    spriteView.play(.waving) { [weak self] in
      guard let self else { return }
      self.applyMovementState()
      self.scheduleRoaming(after: Self.roamingRestInterval)
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

    if isMovementPaused || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
      spriteView.showStatic()
    } else {
      spriteView.play(.idle)
    }
  }

  private func setPanelSize(_ size: CGSize) {
    let currentFrame = panel.frame
    let currentCenterX = currentFrame.midX
    let targetFrame = CGRect(
      x: panel.isVisible ? currentCenterX - size.width / 2 : currentFrame.minX,
      y: currentFrame.minY,
      width: size.width,
      height: size.height
    )

    guard panel.isVisible, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      panel.setFrame(targetFrame, display: true)
      return
    }

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.2
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      panel.animator().setFrame(targetFrame, display: true)
    }
  }

  private func evaluateRoaming() {
    guard isRequestedVisible else { return }
    guard let screen = activeScreen, let obstacles = obstacleProvider.visibleWindowFrames() else {
      temporarilyHide()
      scheduleRoaming(after: Self.unavailableRetryInterval)
      return
    }

    let decision = SafeRoamingPlanner.decide(
      visibleFrame: screen.visibleFrame,
      petSize: panel.frame.size,
      obstacles: obstacles,
      currentOrigin: panel.isVisible ? panel.frame.origin : nil,
      prefersRight: prefersRight,
      screenPadding: Self.screenPadding
    )

    switch decision {
    case .hide:
      temporarilyHide()
      scheduleRoaming(after: Self.unavailableRetryInterval)
    case .reposition(let origin):
      present(at: origin)
      scheduleRoaming(after: Self.roamingRestInterval)
    case .move(let origin):
      if isMovementPaused || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        applyMovementState()
        scheduleRoaming(after: Self.unavailableRetryInterval)
      } else {
        move(to: origin)
      }
    case .rest:
      applyMovementState()
      scheduleRoaming(after: Self.roamingRestInterval)
    }
  }

  private func present(at origin: CGPoint) {
    panel.setFrameOrigin(origin)
    panel.alphaValue = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 1 : 0
    panel.orderFrontRegardless()
    startMouseObservation()
    applyMovementState()
    updateMouseHitTesting(at: NSEvent.mouseLocation)

    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.2
      context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      panel.animator().alphaValue = 1
    }
  }

  private func move(to origin: CGPoint) {
    stopRoamingTimer()
    let distance = abs(origin.x - panel.frame.minX)
    let duration = max(TimeInterval(distance / (Self.roamingSpeed * 0.5)), 0.8)
    let animation: PetAnimation = origin.x >= panel.frame.minX ? .movingRight : .movingLeft
    spriteView.play(animation)

    NSAnimationContext.runAnimationGroup(
      { context in
        context.duration = duration
        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        panel.animator().setFrameOrigin(origin)
      },
      completionHandler: { [weak self] in
        Task { @MainActor in
          guard let self, self.isRequestedVisible else { return }
          self.prefersRight.toggle()
          self.applyMovementState()
          self.updateMouseHitTesting(at: NSEvent.mouseLocation)
          self.scheduleRoaming(after: Self.roamingRestInterval)
        }
      }
    )
  }

  private func temporarilyHide() {
    stopMouseObservation()
    spriteView.stop()
    panel.ignoresMouseEvents = true
    panel.orderOut(nil)
    panel.alphaValue = 1
  }

  private func scheduleRoaming(after interval: TimeInterval) {
    stopRoamingTimer()
    guard isRequestedVisible else { return }

    let timer = Timer(
      timeInterval: interval,
      target: self,
      selector: #selector(roamingTimerFired),
      userInfo: nil,
      repeats: false
    )
    roamingTimer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  @objc private func roamingTimerFired() {
    roamingTimer = nil
    evaluateRoaming()
  }

  private func stopRoamingTimer() {
    roamingTimer?.invalidate()
    roamingTimer = nil
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
