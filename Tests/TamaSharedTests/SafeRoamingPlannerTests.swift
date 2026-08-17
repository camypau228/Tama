import CoreGraphics
import Testing

@testable import TamaShared

@Test
func roamingUsesTheWidestFreeBottomSegment() {
  let decision = SafeRoamingPlanner.decide(
    visibleFrame: CGRect(x: 0, y: 0, width: 1_000, height: 700),
    petSize: CGSize(width: 128, height: 139),
    obstacles: [CGRect(x: 0, y: 0, width: 500, height: 500)],
    currentOrigin: nil,
    prefersRight: true
  )

  guard case .reposition(let origin) = decision else {
    Issue.record("Expected a safe reposition decision")
    return
  }

  #expect(origin.x > 640)
  #expect(origin.y == 24)
}

@Test
func roamingHidesWhenAWindowOccupiesTheWholeCorridor() {
  let decision = SafeRoamingPlanner.decide(
    visibleFrame: CGRect(x: 0, y: 0, width: 1_000, height: 700),
    petSize: CGSize(width: 128, height: 139),
    obstacles: [CGRect(x: 0, y: 0, width: 1_000, height: 700)],
    currentOrigin: nil,
    prefersRight: true
  )

  #expect(decision == .hide)
}

@Test
func roamingMovesOnlyInsideTheCurrentSafeSegment() {
  let decision = SafeRoamingPlanner.decide(
    visibleFrame: CGRect(x: 0, y: 0, width: 1_000, height: 700),
    petSize: CGSize(width: 128, height: 139),
    obstacles: [CGRect(x: 420, y: 0, width: 180, height: 400)],
    currentOrigin: CGPoint(x: 100, y: 24),
    prefersRight: true
  )

  guard case .move(let origin) = decision else {
    Issue.record("Expected movement inside the current segment")
    return
  }

  #expect(origin.x <= 280)
  #expect(origin.y == 24)
}

@Test
func obstaclesAboveThePetDoNotBlockTheBottomCorridor() {
  let decision = SafeRoamingPlanner.decide(
    visibleFrame: CGRect(x: 0, y: 0, width: 1_000, height: 700),
    petSize: CGSize(width: 128, height: 139),
    obstacles: [CGRect(x: 0, y: 400, width: 1_000, height: 200)],
    currentOrigin: CGPoint(x: 300, y: 24),
    prefersRight: true
  )

  #expect(decision == .move(CGPoint(x: 510, y: 24)))
}
