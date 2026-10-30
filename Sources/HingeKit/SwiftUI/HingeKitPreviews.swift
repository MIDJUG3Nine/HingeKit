#if canImport(SwiftUI) && DEBUG
import SwiftUI

private struct FoldDemoView: View {
    @State private var log: [String] = []

    var body: some View {
        FoldReader { fold in
            VStack(spacing: 16) {
                Text(label(for: fold.posture))
                    .font(.largeTitle.weight(.semibold))
                if let angle = fold.angle {
                    Text("\(Int(angle.rounded()))°")
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                List(log.reversed(), id: \.self) { Text($0) }
            }
            .padding(.top, 40)
        }
        .onFoldEvent { event in
            log.append("\(log.count + 1). \(event)")
        }
    }

    private func label(for posture: FoldPosture) -> String {
        switch posture {
        case .noHinge: "No hinge"
        case .closed: "Closed"
        case .halfOpen: "Half open"
        case .flat: "Flat"
        }
    }
}

#Preview("Fold events") {
    FoldDemoView()
        .hingeSimulator()
}
#endif
