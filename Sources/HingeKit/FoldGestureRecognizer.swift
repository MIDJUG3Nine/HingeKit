import Foundation

/// Something the user did with the hinge.
public enum FoldEvent: Equatable, Sendable {
    /// The posture changed, for example from half-open to flat.
    case postureChanged(from: FoldPosture, to: FoldPosture)
    /// The device was opened from closed, like opening a book.
    case opened
    /// The device was folded shut.
    case closed
    /// While open, the user briefly folded the device partway and opened it again,
    /// like flicking to the next page. Needs a source that reports the angle.
    case pageTurn
}

/// Feeds on hinge samples and reports fold gestures.
///
/// It is a plain value type with no timers or system calls, so it can be driven
/// by the real hinge, a simulator panel, or a unit test in the same way.
public struct FoldGestureRecognizer: Sendable {
    public struct Configuration: Sendable {
        /// How far below the resting angle the hinge must dip to count as a page turn, in degrees.
        public var pageTurnDepth: Double = 25
        /// A dip starts once the angle falls this far below the resting angle, in degrees.
        public var dipStartThreshold: Double = 8
        /// The hinge must come back within this many degrees of the resting angle.
        public var returnTolerance: Double = 10
        /// The whole dip must finish within this many seconds.
        public var pageTurnWindow: TimeInterval = 1.0
        /// How quickly the resting angle follows slow drift (0...1, higher is faster).
        public var restFollowRate: Double = 0.2

        public init() {}
    }

    public var configuration: Configuration
    public private(set) var classifier: PostureClassifier

    public var posture: FoldPosture { classifier.posture }

    private var restAngle: Double?
    private var dip: (start: TimeInterval, lowest: Double)?

    public init(configuration: Configuration = .init(), classifier: PostureClassifier = .init()) {
        self.configuration = configuration
        self.classifier = classifier
    }

    /// Processes one sample and returns the events it caused, in order.
    public mutating func process(_ sample: HingeSample) -> [FoldEvent] {
        let previous = classifier.posture
        let current = classifier.update(with: sample)
        var events: [FoldEvent] = []

        if current != previous {
            events.append(.postureChanged(from: previous, to: current))
            if previous == .closed && current.isOpen { events.append(.opened) }
            if previous.isOpen && current == .closed { events.append(.closed) }
        }

        guard current.isOpen, let angle = sample.angle else {
            restAngle = nil
            dip = nil
            return events
        }

        if current != previous && !previous.isOpen {
            restAngle = angle
            dip = nil
            return events
        }

        if trackPageTurn(angle: angle, at: sample.timestamp) {
            events.append(.pageTurn)
        }
        return events
    }

    private mutating func trackPageTurn(angle: Double, at time: TimeInterval) -> Bool {
        guard let rest = restAngle else {
            restAngle = angle
            return false
        }

        guard let current = dip else {
            if rest - angle >= configuration.dipStartThreshold {
                dip = (time, angle)
            } else if angle >= rest {
                restAngle = angle
            } else {
                restAngle = rest + (angle - rest) * configuration.restFollowRate
            }
            return false
        }

        if time - current.start > configuration.pageTurnWindow {
            // Too slow to be a flick: the user is settling at a new angle.
            dip = nil
            restAngle = angle
            return false
        }

        let lowest = min(current.lowest, angle)
        dip = (current.start, lowest)

        if rest - lowest >= configuration.pageTurnDepth && rest - angle <= configuration.returnTolerance {
            dip = nil
            return true
        }
        return false
    }
}
