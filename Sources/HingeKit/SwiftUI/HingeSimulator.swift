#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Adds a small panel that fakes the hinge for every HingeKit view inside this one.
    ///
    /// Use it in Xcode Previews, in the Simulator, or on a phone without a hinge.
    /// While it is enabled, the real hinge is ignored. Wrap it in `#if DEBUG`
    /// so it never ships:
    ///
    /// ```swift
    /// ContentView()
    ///     #if DEBUG
    ///     .hingeSimulator()
    ///     #endif
    /// ```
    func hingeSimulator(_ isEnabled: Bool = true, initialAngle: Double = 120) -> some View {
        modifier(HingeSimulatorModifier(isEnabled: isEnabled, initialAngle: initialAngle))
    }
}

struct HingeSimulatorModifier: ViewModifier {
    let isEnabled: Bool
    @State private var angle: Double
    @State private var sample: HingeSample
    @State private var flick: Task<Void, Never>?

    init(isEnabled: Bool, initialAngle: Double) {
        self.isEnabled = isEnabled
        let angle = min(max(initialAngle, 0), 180)
        _angle = State(initialValue: angle)
        _sample = State(initialValue: Self.sample(for: angle))
    }

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .environment(\.simulatedHingeSample, sample)
                .overlay(alignment: .bottom) { panel }
                .onChange(of: angle) { _, newAngle in
                    sample = Self.sample(for: newAngle)
                }
        } else {
            content
        }
    }

    private var panel: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Hinge \(Int(angle.rounded()))°")
                    .monospacedDigit()
                Spacer()
                Button("Close") { set(0) }
                Button("Flick") { runFlick() }
                    .disabled(angle < 45)
                Button("Flat") { set(180) }
            }
            .font(.footnote.weight(.medium))
            Slider(value: $angle, in: 0...180)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hinge simulator")
    }

    private func set(_ value: Double) {
        flick?.cancel()
        angle = value
    }

    /// Fakes a quick partial fold and back, which `FoldGestureRecognizer` reads as a page turn.
    private func runFlick() {
        flick?.cancel()
        let rest = angle
        let path = [rest - 15, rest - 35, rest - 20, rest - 5, rest]
        flick = Task { @MainActor in
            for value in path {
                try? await Task.sleep(for: .milliseconds(60))
                if Task.isCancelled { return }
                angle = max(value, 10)
            }
        }
    }

    static func sample(for angle: Double) -> HingeSample {
        let status: HingeSample.Status
        switch angle {
        case ...0: status = .closed
        case 180...: status = .fullyOpen
        default: status = .partiallyOpen
        }
        return HingeSample(status: status, angle: angle, timestamp: Date().timeIntervalSinceReferenceDate)
    }
}
#endif
