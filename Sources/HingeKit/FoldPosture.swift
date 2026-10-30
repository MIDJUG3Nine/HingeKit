import Foundation

/// How the device is folded right now, in terms an app can lay out against.
public enum FoldPosture: Equatable, Sendable {
    /// The device has no hinge (regular iPhone, iPad, Mac).
    case noHinge
    /// Folded shut; the app is on the outer display.
    case closed
    /// Bent open, like a book or a laptop.
    case halfOpen
    /// Open and flat, like a small tablet.
    case flat

    public var isOpen: Bool { self == .halfOpen || self == .flat }
}

/// Turns raw samples into a posture, with hysteresis so the posture
/// does not flicker when the hinge rests near a threshold.
public struct PostureClassifier: Sendable {
    /// At or below this angle the device counts as closed, even if the status lags.
    public var closedBelow: Double
    /// At or above this angle a half-open device becomes flat.
    public var flatAbove: Double
    /// How far the angle must move back past a threshold before the posture changes back.
    public var hysteresis: Double

    public private(set) var posture: FoldPosture = .noHinge

    public init(closedBelow: Double = 8, flatAbove: Double = 165, hysteresis: Double = 10) {
        self.closedBelow = closedBelow
        self.flatAbove = flatAbove
        self.hysteresis = hysteresis
    }

    @discardableResult
    public mutating func update(with sample: HingeSample) -> FoldPosture {
        posture = classify(sample, previous: posture)
        return posture
    }

    func classify(_ sample: HingeSample, previous: FoldPosture) -> FoldPosture {
        if sample.status == .closed { return .closed }
        let angle = sample.effectiveAngle

        switch previous {
        case .closed:
            if angle <= closedBelow + hysteresis { return .closed }
        case .flat:
            if angle >= flatAbove - hysteresis { return .flat }
        case .noHinge, .halfOpen:
            break
        }

        if angle <= closedBelow { return .closed }
        if angle >= flatAbove { return .flat }
        return .halfOpen
    }
}
