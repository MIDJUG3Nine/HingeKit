/// HingeKit turns the iPhone Duo hinge into input for SwiftUI apps.
///
/// - `FoldGestureRecognizer` and `PostureClassifier` are plain value types that turn
///   hinge samples into postures and gestures (opened, closed, page turn).
/// - `.onFoldEvent(perform:)` and `FoldReader` connect them to SwiftUI views.
/// - `.hingeSimulator()` adds a debug panel that fakes the hinge on any device,
///   in Xcode Previews and in the Simulator.
public enum HingeKit {
    public static let version = "0.1.0"
}
