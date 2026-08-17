import Testing

@testable import TamaShared

@Test
func atlasLayoutMatchesVersionTwoContract() {
  #expect(SterlingAtlasLayout.columns == 8)
  #expect(SterlingAtlasLayout.rows == 11)
  #expect(SterlingAtlasLayout.pixelWidth == 1_536)
  #expect(SterlingAtlasLayout.pixelHeight == 2_288)
}

@Test
func standardAnimationsUseExpectedRowsAndFrameCounts() {
  let expected: [(PetAnimation, Int, Int)] = [
    (.idle, 0, 6),
    (.movingRight, 1, 8),
    (.movingLeft, 2, 8),
    (.waving, 3, 4),
    (.jumping, 4, 5),
    (.warning, 5, 8),
    (.waiting, 6, 6),
    (.activeWork, 7, 6),
    (.observing, 8, 6),
  ]

  for (animation, row, frameCount) in expected {
    #expect(animation.row == row)
    #expect(animation.frameDurations.count == frameCount)
  }
}

@Test
func onlyReactionAnimationsStopAfterOneCycle() {
  #expect(!PetAnimation.waving.repeats)
  #expect(!PetAnimation.jumping.repeats)
  #expect(!PetAnimation.warning.repeats)
  #expect(PetAnimation.idle.repeats)
  #expect(PetAnimation.activeWork.repeats)
}
