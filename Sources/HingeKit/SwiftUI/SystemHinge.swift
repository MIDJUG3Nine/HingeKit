#if canImport(SwiftUI)
import SwiftUI

/// Reads the real hinge through `onHingeChange`, available from iOS 27.1.
/// On older systems and devices without a hinge it does nothing.
struct SystemHingeModifier: ViewModifier {
    let isEnabled: Bool
    let onSample: @MainActor (HingeSample) -> Void

    func body(content: Content) -> some View {
        #if canImport(SwiftUI, _version: 8.0.85)
        if #available(iOS 27.1, macOS 27.1, *) {
            content.onHingeChange(isEnabled: isEnabled) { _, newContext in
                guard let hinge = newContext.hinge else { return }
                let sample = HingeSample(hinge, timestamp: Date().timeIntervalSinceReferenceDate)
                MainActor.assumeIsolated { onSample(sample) }
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#if canImport(SwiftUI, _version: 8.0.85)
@available(iOS 27.1, macOS 27.1, *)
extension HingeSample {
    /// Converts SwiftUI's `DeviceHinge`, whose angle is a SwiftUI `Angle`.
    init(_ hinge: DeviceHinge, timestamp: TimeInterval) {
        let status: Status
        if hinge.status == .closed {
            status = .closed
        } else if hinge.status == .fullyOpen {
            status = .fullyOpen
        } else {
            status = .partiallyOpen
        }
        self.init(status: status, angle: hinge.angle.degrees, timestamp: timestamp)
    }
}
#endif
#endif
