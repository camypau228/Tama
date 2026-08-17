import CoreGraphics

public enum RoamingDecision: Equatable, Sendable {
  case hide
  case reposition(CGPoint)
  case move(CGPoint)
  case rest
}

public enum SafeRoamingPlanner {
  public static func decide(
    visibleFrame: CGRect,
    petSize: CGSize,
    obstacles: [CGRect],
    currentOrigin: CGPoint?,
    prefersRight: Bool,
    screenPadding: CGFloat = 24,
    obstacleClearance: CGFloat = 12,
    minimumTravel: CGFloat = 48,
    maximumTravel: CGFloat = 210
  ) -> RoamingDecision {
    let minimumX = visibleFrame.minX + screenPadding
    let maximumX = visibleFrame.maxX - screenPadding - petSize.width
    let originY = visibleFrame.minY + screenPadding

    guard minimumX <= maximumX, petSize.width > 0, petSize.height > 0 else {
      return .hide
    }

    let allowedRange = minimumX...maximumX
    let petVerticalRange =
      (originY - obstacleClearance)...(originY + petSize.height + obstacleClearance)
    let forbiddenRanges = obstacles.compactMap { obstacle -> ClosedRange<CGFloat>? in
      guard verticalRange(of: obstacle).overlaps(petVerticalRange) else { return nil }

      let lowerBound = max(
        allowedRange.lowerBound,
        obstacle.minX - obstacleClearance - petSize.width
      )
      let upperBound = min(allowedRange.upperBound, obstacle.maxX + obstacleClearance)
      return lowerBound <= upperBound ? lowerBound...upperBound : nil
    }
    let safeRanges = subtract(merging: forbiddenRanges, from: allowedRange)

    guard !safeRanges.isEmpty else { return .hide }

    if let currentOrigin,
      abs(currentOrigin.y - originY) < 1,
      let currentRange = safeRanges.first(where: { $0.contains(currentOrigin.x) })
    {
      let preferredTarget = target(
        from: currentOrigin.x,
        in: currentRange,
        movingRight: prefersRight,
        maximumTravel: maximumTravel
      )
      if abs(preferredTarget - currentOrigin.x) >= minimumTravel {
        return .move(CGPoint(x: preferredTarget, y: originY))
      }

      let alternateTarget = target(
        from: currentOrigin.x,
        in: currentRange,
        movingRight: !prefersRight,
        maximumTravel: maximumTravel
      )
      if abs(alternateTarget - currentOrigin.x) >= minimumTravel {
        return .move(CGPoint(x: alternateTarget, y: originY))
      }

      return .rest
    }

    guard let widestRange = safeRanges.max(by: { width(of: $0) < width(of: $1) }) else {
      return .hide
    }
    let centeredX = widestRange.lowerBound + width(of: widestRange) / 2
    return .reposition(CGPoint(x: centeredX, y: originY))
  }

  private static func verticalRange(of rectangle: CGRect) -> ClosedRange<CGFloat> {
    rectangle.minY...rectangle.maxY
  }

  private static func width(of range: ClosedRange<CGFloat>) -> CGFloat {
    range.upperBound - range.lowerBound
  }

  private static func target(
    from currentX: CGFloat,
    in range: ClosedRange<CGFloat>,
    movingRight: Bool,
    maximumTravel: CGFloat
  ) -> CGFloat {
    if movingRight {
      return min(currentX + maximumTravel, range.upperBound)
    }
    return max(currentX - maximumTravel, range.lowerBound)
  }

  private static func subtract(
    merging forbiddenRanges: [ClosedRange<CGFloat>],
    from allowedRange: ClosedRange<CGFloat>
  ) -> [ClosedRange<CGFloat>] {
    let sortedRanges = forbiddenRanges.sorted { $0.lowerBound < $1.lowerBound }
    var mergedRanges: [ClosedRange<CGFloat>] = []

    for range in sortedRanges {
      guard let last = mergedRanges.last else {
        mergedRanges.append(range)
        continue
      }

      if range.lowerBound <= last.upperBound {
        mergedRanges[mergedRanges.count - 1] =
          last
          .lowerBound...max(
            last.upperBound,
            range.upperBound
          )
      } else {
        mergedRanges.append(range)
      }
    }

    var safeRanges: [ClosedRange<CGFloat>] = []
    var cursor = allowedRange.lowerBound

    for range in mergedRanges {
      if cursor < range.lowerBound {
        safeRanges.append(cursor...range.lowerBound)
      }
      cursor = max(cursor, range.upperBound)
    }

    if cursor < allowedRange.upperBound {
      safeRanges.append(cursor...allowedRange.upperBound)
    }

    return safeRanges
  }
}
