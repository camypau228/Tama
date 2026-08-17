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
      try checkSafeRoaming()

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

  private static func checkSafeRoaming() throws {
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 700)
    let petSize = CGSize(width: 128, height: 139)

    let safeDecision = SafeRoamingPlanner.decide(
      visibleFrame: visibleFrame,
      petSize: petSize,
      obstacles: [CGRect(x: 0, y: 0, width: 500, height: 500)],
      currentOrigin: nil,
      prefersRight: true
    )
    guard case .reposition(let safeOrigin) = safeDecision else {
      throw CheckError(message: "safe roaming did not choose a free segment")
    }
    try require(safeOrigin.x > 640, "safe roaming chose an obstructed segment")

    let blockedDecision = SafeRoamingPlanner.decide(
      visibleFrame: visibleFrame,
      petSize: petSize,
      obstacles: [visibleFrame],
      currentOrigin: nil,
      prefersRight: true
    )
    try require(blockedDecision == .hide, "safe roaming did not hide without free space")

    let moveDecision = SafeRoamingPlanner.decide(
      visibleFrame: visibleFrame,
      petSize: petSize,
      obstacles: [CGRect(x: 420, y: 0, width: 180, height: 400)],
      currentOrigin: CGPoint(x: 100, y: 24),
      prefersRight: true
    )
    guard case .move(let moveOrigin) = moveDecision else {
      throw CheckError(message: "safe roaming did not move inside the current segment")
    }
    try require(moveOrigin.x <= 280, "safe roaming crossed an obstacle")
  }

  private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw CheckError(message: message) }
  }
}

private struct CheckError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}
