import Testing
@testable import HingeKit

/// Builds samples 50 ms apart from a list of angles.
private func samples(_ angles: [Double], start: Double = 0, step: Double = 0.05) -> [HingeSample] {
    angles.enumerated().map { index, angle in
        let status: HingeSample.Status = angle <= 0 ? .closed : (angle >= 180 ? .fullyOpen : .partiallyOpen)
        return HingeSample(status: status, angle: angle, timestamp: start + Double(index) * step)
    }
}

private func run(_ recognizer: inout FoldGestureRecognizer, _ input: [HingeSample]) -> [FoldEvent] {
    input.flatMap { recognizer.process($0) }
}

@Suite struct PostureClassifierTests {
    @Test func statusClosedWins() {
        var classifier = PostureClassifier()
        #expect(classifier.update(with: HingeSample(status: .closed, angle: 40, timestamp: 0)) == .closed)
    }

    @Test func thresholds() {
        var classifier = PostureClassifier()
        #expect(classifier.update(with: HingeSample(status: .partiallyOpen, angle: 90, timestamp: 0)) == .halfOpen)
        #expect(classifier.update(with: HingeSample(status: .partiallyOpen, angle: 170, timestamp: 1)) == .flat)
        #expect(classifier.update(with: HingeSample(status: .partiallyOpen, angle: 4, timestamp: 2)) == .closed)
    }

    @Test func hysteresisKeepsFlatNearThreshold() {
        var classifier = PostureClassifier()
        classifier.update(with: HingeSample(status: .fullyOpen, angle: 180, timestamp: 0))
        #expect(classifier.update(with: HingeSample(status: .partiallyOpen, angle: 158, timestamp: 1)) == .flat)
        #expect(classifier.update(with: HingeSample(status: .partiallyOpen, angle: 150, timestamp: 2)) == .halfOpen)
        #expect(classifier.update(with: HingeSample(status: .partiallyOpen, angle: 160, timestamp: 3)) == .halfOpen)
    }

    @Test func statusOnlySourcesStillWork() {
        var classifier = PostureClassifier()
        #expect(classifier.update(with: HingeSample(status: .partiallyOpen, timestamp: 0)) == .halfOpen)
        #expect(classifier.update(with: HingeSample(status: .fullyOpen, timestamp: 1)) == .flat)
    }

    @Test func angleIsClamped() {
        #expect(HingeSample(status: .fullyOpen, angle: 200, timestamp: 0).angle == 180)
        #expect(HingeSample(status: .closed, angle: -5, timestamp: 0).angle == 0)
    }
}

@Suite struct FoldGestureRecognizerTests {
    @Test func openingAndClosingABook() {
        var recognizer = FoldGestureRecognizer()
        let events = run(&recognizer, samples([0, 0, 30, 80, 120, 120, 60, 10, 0]))
        #expect(events.contains(.opened))
        #expect(events.contains(.closed))
        #expect(events.firstIndex(of: .opened)! < events.firstIndex(of: .closed)!)
        #expect(!events.contains(.pageTurn))
    }

    @Test func quickDipIsAPageTurn() {
        var recognizer = FoldGestureRecognizer()
        _ = run(&recognizer, samples([0, 60, 120, 120, 120]))
        let events = run(&recognizer, samples([110, 95, 88, 100, 115, 119], start: 1))
        #expect(events.filter { $0 == .pageTurn }.count == 1)
    }

    @Test func shallowWobbleIsNotAPageTurn() {
        var recognizer = FoldGestureRecognizer()
        _ = run(&recognizer, samples([0, 60, 120, 120]))
        let events = run(&recognizer, samples([114, 108, 104, 110, 118, 120], start: 1))
        #expect(!events.contains(.pageTurn))
    }

    @Test func slowFoldIsNotAPageTurn() {
        var recognizer = FoldGestureRecognizer()
        _ = run(&recognizer, samples([0, 60, 120, 120]))
        // The same dip as quickDipIsAPageTurn, but spread over 2.5 seconds.
        let events = run(&recognizer, samples([110, 95, 88, 100, 115, 119], start: 1, step: 0.5))
        #expect(!events.contains(.pageTurn))
    }

    @Test func dipThatNeverComesBackIsNotAPageTurn() {
        var recognizer = FoldGestureRecognizer()
        _ = run(&recognizer, samples([0, 60, 120, 120]))
        let events = run(&recognizer, samples([110, 95, 88, 85, 85, 85], start: 1))
        #expect(!events.contains(.pageTurn))
    }

    @Test func twoFlicksAreTwoPageTurns() {
        var recognizer = FoldGestureRecognizer()
        _ = run(&recognizer, samples([0, 60, 150, 150]))
        let first = run(&recognizer, samples([135, 115, 140, 150, 150], start: 1))
        let second = run(&recognizer, samples([135, 115, 140, 150], start: 3))
        #expect(first.filter { $0 == .pageTurn }.count == 1)
        #expect(second.filter { $0 == .pageTurn }.count == 1)
    }

    @Test func pageTurnFromFlat() {
        var recognizer = FoldGestureRecognizer()
        _ = run(&recognizer, samples([0, 90, 180, 180]))
        let events = run(&recognizer, samples([165, 145, 170, 180], start: 1))
        #expect(events.contains(.pageTurn))
        #expect(recognizer.posture == .flat)
    }

    @Test func statusOnlySourceReportsOpenAndCloseButNoPageTurn() {
        var recognizer = FoldGestureRecognizer()
        let input = [
            HingeSample(status: .closed, timestamp: 0),
            HingeSample(status: .partiallyOpen, timestamp: 1),
            HingeSample(status: .fullyOpen, timestamp: 2),
            HingeSample(status: .closed, timestamp: 3),
        ]
        let events = run(&recognizer, input)
        #expect(events.filter { $0 == .opened }.count == 1)
        #expect(events.filter { $0 == .closed }.count == 1)
        #expect(!events.contains(.pageTurn))
    }

    @Test func firstSampleFromNoHingeIsNotAnOpening() {
        var recognizer = FoldGestureRecognizer()
        let events = recognizer.process(HingeSample(status: .partiallyOpen, angle: 120, timestamp: 0))
        #expect(events == [.postureChanged(from: .noHinge, to: .halfOpen)])
    }
}
