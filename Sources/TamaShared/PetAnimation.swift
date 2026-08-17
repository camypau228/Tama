import Foundation

public enum PetAnimation: String, CaseIterable, Sendable {
  case idle
  case movingRight
  case movingLeft
  case waving
  case jumping
  case warning
  case waiting
  case activeWork
  case observing

  public var row: Int {
    switch self {
    case .idle: 0
    case .movingRight: 1
    case .movingLeft: 2
    case .waving: 3
    case .jumping: 4
    case .warning: 5
    case .waiting: 6
    case .activeWork: 7
    case .observing: 8
    }
  }

  public var frameDurations: [TimeInterval] {
    milliseconds.map { TimeInterval($0) / 1_000 }
  }

  public var repeats: Bool {
    switch self {
    case .waving, .jumping, .warning: false
    default: true
    }
  }

  public var cyclePause: TimeInterval {
    self == .idle ? 2.5 : 0
  }

  private var milliseconds: [Int] {
    switch self {
    case .idle: [280, 110, 110, 140, 140, 320]
    case .movingRight, .movingLeft: [120, 120, 120, 120, 120, 120, 120, 220]
    case .waving: [140, 140, 140, 280]
    case .jumping: [140, 140, 140, 140, 280]
    case .warning: [140, 140, 140, 140, 140, 140, 140, 240]
    case .waiting: [150, 150, 150, 150, 150, 260]
    case .activeWork: [120, 120, 120, 120, 120, 220]
    case .observing: [150, 150, 150, 150, 150, 280]
    }
  }
}

public struct SpriteFrame: Hashable, Sendable {
  public let column: Int
  public let row: Int

  public init(column: Int, row: Int) {
    self.column = column
    self.row = row
  }
}

public enum SterlingAtlasLayout {
  public static let columns = 8
  public static let rows = 11
  public static let cellWidth = 192
  public static let cellHeight = 208
  public static let pixelWidth = columns * cellWidth
  public static let pixelHeight = rows * cellHeight
}

public enum SterlingDisplayMetrics {
  public static let regularWidth = 128.0
  public static let regularHeight = 139.0

  public static func size(for scale: PetScale) -> (width: Double, height: Double) {
    (
      width: regularWidth * scale.rawValue,
      height: regularHeight * scale.rawValue
    )
  }
}

public enum PetScale: Double, CaseIterable, Identifiable, Sendable {
  case small = 0.75
  case regular = 1.0
  case large = 1.25

  public var id: Double { rawValue }

  public var title: String {
    switch self {
    case .small: "75%"
    case .regular: "100%"
    case .large: "125%"
    }
  }
}
