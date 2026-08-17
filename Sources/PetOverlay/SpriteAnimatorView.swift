import AppKit
import QuartzCore
import TamaShared

@MainActor
public final class SpriteAnimatorView: NSView {
  public var onPetClick: (() -> Void)?
  public var onFrameChanged: (() -> Void)?

  public private(set) var currentFrame = SpriteFrame(column: 0, row: PetAnimation.idle.row)

  private let atlas: SpriteAtlas
  private let spriteLayer = CALayer()
  private var animation = PetAnimation.idle
  private var frameIndex = 0
  private var timer: Timer?
  private var completion: (() -> Void)?

  public init(atlas: SpriteAtlas) {
    self.atlas = atlas
    super.init(frame: .zero)

    wantsLayer = true
    layer?.addSublayer(spriteLayer)
    spriteLayer.contentsGravity = .resizeAspect
    spriteLayer.magnificationFilter = .linear
    spriteLayer.minificationFilter = .trilinear
    displayCurrentFrame()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  public override var isFlipped: Bool { false }

  public override func layout() {
    super.layout()
    spriteLayer.frame = bounds
  }

  public override func viewWillMove(toWindow newWindow: NSWindow?) {
    if newWindow == nil {
      stop()
    }
    super.viewWillMove(toWindow: newWindow)
  }

  public override func mouseDown(with event: NSEvent) {
    onPetClick?()
  }

  public func play(_ animation: PetAnimation, completion: (() -> Void)? = nil) {
    stopTimer()
    self.animation = animation
    self.completion = completion
    frameIndex = 0
    displayCurrentFrame()
    scheduleNextFrame()
  }

  public func showStatic(_ animation: PetAnimation = .idle) {
    stopTimer()
    self.animation = animation
    completion = nil
    frameIndex = 0
    displayCurrentFrame()
  }

  public func stop() {
    stopTimer()
    completion = nil
  }

  public func isVisible(at point: CGPoint) -> Bool {
    atlas.isVisible(frame: currentFrame, at: point, in: bounds.size)
  }

  private func displayCurrentFrame() {
    currentFrame = SpriteFrame(column: frameIndex, row: animation.row)
    let shouldReduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    if spriteLayer.contents != nil, !shouldReduceMotion {
      let transition = CATransition()
      transition.duration = animation == .idle ? 0.1 : 0.07
      transition.type = .fade
      transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      spriteLayer.add(transition, forKey: "frameTransition")
    }

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    spriteLayer.contents = atlas.image(for: currentFrame)
    CATransaction.commit()
    onFrameChanged?()
  }

  private func scheduleNextFrame() {
    var duration = animation.frameDurations[frameIndex]
    if animation.repeats, frameIndex == animation.frameDurations.count - 1 {
      duration += animation.cyclePause
    }
    let timer = Timer(
      timeInterval: duration,
      target: self,
      selector: #selector(advanceFrame),
      userInfo: nil,
      repeats: false
    )
    self.timer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  @objc private func advanceFrame() {
    timer = nil
    let nextFrame = frameIndex + 1

    if nextFrame < animation.frameDurations.count {
      frameIndex = nextFrame
      displayCurrentFrame()
      scheduleNextFrame()
      return
    }

    if animation.repeats {
      frameIndex = 0
      displayCurrentFrame()
      scheduleNextFrame()
      return
    }

    let finished = completion
    completion = nil
    finished?()
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }
}
