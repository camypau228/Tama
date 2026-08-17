import Darwin
import Foundation
import PetOverlay
import TamaShared

@main
enum TamaChecks {
  @MainActor
  static func main() {
    do {
      let atlas = try SpriteAtlas()
      try checkAtlasDimensions(atlas)
      try checkAnimationFrames(atlas)
      try checkLookDirections(atlas)
      try checkPresentationMetrics()

      do {
        try checkUnusedCells(atlas)
      } catch {
        if CommandLine.arguments.contains("--strict-package") {
          throw error
        }
        print("WARNING: \(error.localizedDescription)")
      }

      print("All Sterling runtime checks passed")
    } catch {
      print("FAIL: \(error.localizedDescription)")
      exit(EXIT_FAILURE)
    }
  }

  @MainActor
  private static func checkAtlasDimensions(_ atlas: SpriteAtlas) throws {
    try require(
      Int(atlas.pixelSize.width) == SterlingAtlasLayout.pixelWidth
        && Int(atlas.pixelSize.height) == SterlingAtlasLayout.pixelHeight,
      "atlas dimensions do not match the v2 contract"
    )
  }

  @MainActor
  private static func checkAnimationFrames(_ atlas: SpriteAtlas) throws {
    for animation in PetAnimation.allCases {
      for column in animation.frameDurations.indices {
        try require(
          atlas.hasVisiblePixels(frame: SpriteFrame(column: column, row: animation.row)),
          "missing \(animation.rawValue) frame \(column)"
        )
      }
    }
  }

  @MainActor
  private static func checkUnusedCells(_ atlas: SpriteAtlas) throws {
    var populatedCells: [String] = []

    for animation in PetAnimation.allCases {
      for column in animation.frameDurations.count..<SterlingAtlasLayout.columns {
        if atlas.hasVisiblePixels(frame: SpriteFrame(column: column, row: animation.row)) {
          populatedCells.append("\(animation.row):\(column)")
        }
      }
    }

    try require(
      populatedCells.isEmpty,
      "unused cells are not transparent: \(populatedCells.joined(separator: ", "))"
    )
  }

  @MainActor
  private static func checkLookDirections(_ atlas: SpriteAtlas) throws {
    for row in 9...10 {
      for column in 0..<SterlingAtlasLayout.columns {
        try require(
          atlas.hasVisiblePixels(frame: SpriteFrame(column: column, row: row)),
          "missing look direction at row \(row), column \(column)"
        )
      }
    }
  }

  private static func checkPresentationMetrics() throws {
    let regular = SterlingDisplayMetrics.size(for: .regular)
    let small = SterlingDisplayMetrics.size(for: .small)
    let large = SterlingDisplayMetrics.size(for: .large)

    try require(regular.width == 128 && regular.height == 139, "unexpected regular pet size")
    try require(small.width == 96 && small.height == 104.25, "unexpected small pet size")
    try require(large.width == 160 && large.height == 173.75, "unexpected large pet size")
    try require(PetAnimation.idle.cyclePause >= 2.5, "idle cycle pause is too short")
  }

  private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw CheckError(message: message) }
  }
}

private struct CheckError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}
