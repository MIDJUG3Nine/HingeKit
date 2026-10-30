import Foundation

/// One reading of the hinge, independent of the system API that produced it.
public struct HingeSample: Equatable, Sendable {
    /// What the system reports about the hinge.
    public enum Status: Equatable, Sendable {
        case closed
        case partiallyOpen
        case fullyOpen
    }

    public var status: Status

    /// Opening angle in degrees, from 0 (closed) to 180 (flat).
    /// `nil` when the source only reports a status.
    public var angle: Double?

    /// Seconds on any clock. Only differences between samples matter.
    public var timestamp: TimeInterval

    public init(status: Status, angle: Double? = nil, timestamp: TimeInterval) {
        self.status = status
        self.angle = angle.map { min(max($0, 0), 180) }
        self.timestamp = timestamp
    }

    /// The angle, falling back to a typical value for the status.
    var effectiveAngle: Double {
        if let angle { return angle }
        switch status {
        case .closed: return 0
        case .partiallyOpen: return 90
        case .fullyOpen: return 180
        }
    }
}
