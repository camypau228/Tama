import AppKit
import CoreGraphics
import TamaShared

@MainActor
public final class SpriteAtlas {
  public enum LoadError: LocalizedError {
    case missingResource
    case unreadableResource
    case invalidDimensions(width: Int, height: Int)

    public var errorDescription: String? {
      switch self {
      case .missingResource:
        "Ресурс Sterling не найден в приложении."
      case .unreadableResource:
        "Не удалось прочитать атлас Sterling."
      case .invalidDimensions(let width, let height):
        "Некорректный размер атласа Sterling: \(width)×\(height)."
      }
    }
  }

  private let atlasImage: CGImage
  private var frameCache: [SpriteFrame: CGImage] = [:]
  private var alphaCache: [SpriteFrame: AlphaMask] = [:]

  public init() throws {
    guard
      let url = Bundle.module.url(
        forResource: "spritesheet",
        withExtension: "webp",
        subdirectory: "Sterling"
      ) ?? Bundle.module.url(forResource: "spritesheet", withExtension: "webp")
    else {
      throw LoadError.missingResource
    }

    guard
      let image = NSImage(contentsOf: url),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
      throw LoadError.unreadableResource
    }

    guard
      cgImage.width == SterlingAtlasLayout.pixelWidth,
      cgImage.height == SterlingAtlasLayout.pixelHeight
    else {
      throw LoadError.invalidDimensions(width: cgImage.width, height: cgImage.height)
    }

    atlasImage = cgImage
  }

  public var pixelSize: CGSize {
    CGSize(width: atlasImage.width, height: atlasImage.height)
  }

  public func image(for frame: SpriteFrame) -> CGImage? {
    guard
      (0..<SterlingAtlasLayout.columns).contains(frame.column),
      (0..<SterlingAtlasLayout.rows).contains(frame.row)
    else {
      return nil
    }

    if let cached = frameCache[frame] {
      return cached
    }

    let crop = CGRect(
      x: frame.column * SterlingAtlasLayout.cellWidth,
      y: frame.row * SterlingAtlasLayout.cellHeight,
      width: SterlingAtlasLayout.cellWidth,
      height: SterlingAtlasLayout.cellHeight
    )
    guard let image = atlasImage.cropping(to: crop) else { return nil }

    frameCache[frame] = image
    return image
  }

  public func isVisible(frame: SpriteFrame, at point: CGPoint, in size: CGSize) -> Bool {
    guard
      size.width > 0,
      size.height > 0,
      point.x >= 0,
      point.y >= 0,
      point.x < size.width,
      point.y < size.height,
      let mask = alphaMask(for: frame)
    else {
      return false
    }

    let x = min(
      SterlingAtlasLayout.cellWidth - 1,
      Int(point.x / size.width * CGFloat(SterlingAtlasLayout.cellWidth))
    )
    let yFromBottom = min(
      SterlingAtlasLayout.cellHeight - 1,
      Int(point.y / size.height * CGFloat(SterlingAtlasLayout.cellHeight))
    )
    let y = SterlingAtlasLayout.cellHeight - 1 - yFromBottom

    return mask.alpha(x: x, y: y) >= 24
  }

  public func hasVisiblePixels(frame: SpriteFrame) -> Bool {
    alphaMask(for: frame)?.containsVisiblePixels == true
  }

  public func menuBarIcon() -> NSImage? {
    guard
      let frame = image(for: SpriteFrame(column: 0, row: PetAnimation.idle.row)),
      let head = frame.cropping(to: CGRect(x: 44, y: 0, width: 112, height: 112))
    else {
      return nil
    }

    let image = NSImage(cgImage: head, size: NSSize(width: 18, height: 18))
    image.isTemplate = true
    return image
  }

  private func alphaMask(for frame: SpriteFrame) -> AlphaMask? {
    if let cached = alphaCache[frame] {
      return cached
    }
    guard let image = image(for: frame), let mask = AlphaMask(image: image) else { return nil }

    alphaCache[frame] = mask
    return mask
  }
}

private struct AlphaMask {
  let pixels: [UInt8]

  init?(image: CGImage) {
    let width = SterlingAtlasLayout.cellWidth
    let height = SterlingAtlasLayout.cellHeight
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)

    let didDraw = pixels.withUnsafeMutableBytes { bytes -> Bool in
      guard
        let context = CGContext(
          data: bytes.baseAddress,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: bytesPerRow,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
      else {
        return false
      }

      context.translateBy(x: 0, y: CGFloat(height))
      context.scaleBy(x: 1, y: -1)
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }

    guard didDraw else { return nil }
    self.pixels = pixels
  }

  var containsVisiblePixels: Bool {
    stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] >= 24 }
  }

  func alpha(x: Int, y: Int) -> UInt8 {
    pixels[((y * SterlingAtlasLayout.cellWidth) + x) * 4 + 3]
  }
}
