#if canImport(SwiftUI)
import SwiftUI

/// The fold state a view can lay out against.
public struct FoldState: Equatable, Sendable {
    public var posture: FoldPosture
    /// Opening angle in degrees, when the source reports one.
    public var angle: Double?

    public init(posture: FoldPosture, angle: Double? = nil) {
        self.posture = posture
        self.angle = angle
    }
}

public extension View {
    /// Calls `action` for every fold gesture: opened, closed, page turn and posture changes.
    ///
    /// On devices without a hinge nothing is reported, unless a `.hingeSimulator()`
    /// higher up in the view tree is faking one.
    func onFoldEvent(perform action: @escaping @MainActor (FoldEvent) -> Void) -> some View {
        modifier(FoldEventModifier(action: action))
    }
}

/// A container that hands its content the current fold state.
///
/// ```swift
/// FoldReader { fold in
///     if fold.posture == .halfOpen { TwoPaneView() } else { SinglePaneView() }
/// }
/// ```
public struct FoldReader<Content: View>: View {
    @State private var classifier = PostureClassifier()
    @State private var state = FoldState(posture: .noHinge)
    private let content: (FoldState) -> Content

    public init(@ViewBuilder content: @escaping (FoldState) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(state)
            .modifier(HingeSampleReader { sample in
                let posture = classifier.update(with: sample)
                state = FoldState(posture: posture, angle: sample.angle)
            })
    }
}

struct FoldEventModifier: ViewModifier {
    @State private var recognizer = FoldGestureRecognizer()
    let action: @MainActor (FoldEvent) -> Void

    func body(content: Content) -> some View {
        content.modifier(HingeSampleReader { sample in
            for event in recognizer.process(sample) {
                action(event)
            }
        })
    }
}

/// Delivers hinge samples from the simulator panel when one is active, otherwise from the system.
struct HingeSampleReader: ViewModifier {
    @Environment(\.simulatedHingeSample) private var simulated
    let onSample: @MainActor (HingeSample) -> Void

    func body(content: Content) -> some View {
        content
            .modifier(SystemHingeModifier(isEnabled: simulated == nil, onSample: onSample))
            .onChange(of: simulated, initial: true) { _, sample in
                if let sample { onSample(sample) }
            }
    }
}

extension EnvironmentValues {
    @Entry var simulatedHingeSample: HingeSample?
}
#endif
