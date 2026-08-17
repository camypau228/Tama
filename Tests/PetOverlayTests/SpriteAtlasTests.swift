import TamaShared
import Testing

@testable import PetOverlay

@MainActor
@Test
func bundledAtlasHasExpectedDimensions() throws {
  let atlas = try SpriteAtlas()

  #expect(Int(atlas.pixelSize.width) == SterlingAtlasLayout.pixelWidth)
  #expect(Int(atlas.pixelSize.height) == SterlingAtlasLayout.pixelHeight)
}

@MainActor
@Test
func everyDeclaredAnimationFrameContainsVisiblePixels() throws {
  let atlas = try SpriteAtlas()

  for animation in PetAnimation.allCases {
    for column in animation.frameDurations.indices {
      #expect(
        atlas.hasVisiblePixels(frame: SpriteFrame(column: column, row: animation.row)),
        "Missing pixels for \(animation.rawValue) frame \(column)"
      )
    }
  }
}

@MainActor
@Test
func allLookDirectionCellsContainVisiblePixels() throws {
  let atlas = try SpriteAtlas()

  for row in 9...10 {
    for column in 0..<SterlingAtlasLayout.columns {
      #expect(
        atlas.hasVisiblePixels(frame: SpriteFrame(column: column, row: row)),
        "Missing look direction at row \(row), column \(column)"
      )
    }
  }
}
