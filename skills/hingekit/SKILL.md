---
name: hingekit
description: Use when building SwiftUI features that react to the iPhone Duo hinge (opening, closing, flicking to turn a page, laying out by fold posture) or when testing fold logic without the device. Covers installing HingeKit, its APIs, the hinge simulator panel and common mistakes.
---

# HingeKit

HingeKit turns the iPhone Duo hinge into input for SwiftUI: `opened`, `closed` and `pageTurn` events, a fold posture, and a simulator panel for building without the device. Repository: https://github.com/MIDJUG3Nine/HingeKit

## When to use it

- The app should do something when the user opens, closes or briefly flicks the device (book-like apps, games, reveals, timers).
- A layout should change between closed, half-open (book or laptop shape) and flat.
- Fold logic needs testing in Xcode Previews, an ordinary simulator or a phone without a hinge.

For window layout across the crease (`reservedRegions`, `ArrangementView`), use Apple's APIs directly. HingeKit is about the hinge as an input.

## Install

```swift
// Package.swift
.package(url: "https://github.com/MIDJUG3Nine/HingeKit.git", from: "0.1.0")
// target dependency
.product(name: "HingeKit", package: "HingeKit")
```

In an Xcode project: File → Add Package Dependencies → paste the URL.

Requirements: Xcode 27.1 or later to read the real hinge (iOS 27.1 SDK). The package's minimum is iOS 17 / macOS 14; on systems or devices without a hinge, posture is `.noHinge` and no events fire, so no availability checks are needed in app code.

## API

```swift
import HingeKit

// 1. Events
SomeView()
    .onFoldEvent { event in
        switch event {
        case .opened: ...            // closed → open
        case .closed: ...            // open → closed
        case .pageTurn: ...          // quick partial fold and back while open
        case .postureChanged(let from, let to): ...
        }
    }

// 2. Posture for layout
FoldReader { fold in
    switch fold.posture {           // .noHinge, .closed, .halfOpen, .flat
    case .halfOpen: TopAndBottomLayout()
    case .flat: TwoColumnLayout()
    case .closed, .noHinge: CompactLayout()
    }
    // fold.angle: Double? in degrees, 0 closed … 180 flat
}

// 3. Simulator panel (debug only)
ContentView()
    #if DEBUG
    .hingeSimulator()               // slider + Close / Flick / Flat buttons
    #endif

// 4. Core without SwiftUI (value types, deterministic)
var recognizer = FoldGestureRecognizer()
let events = recognizer.process(HingeSample(status: .partiallyOpen, angle: 120, timestamp: t))
```

Page-turn tuning lives in `FoldGestureRecognizer.Configuration`: `pageTurnDepth` (25°), `dipStartThreshold` (8°), `returnTolerance` (10°), `pageTurnWindow` (1.0 s), `restFollowRate` (0.2). Posture thresholds are on `PostureClassifier`: `closedBelow` (8°), `flatAbove` (165°), `hysteresis` (10°).

## Testing

- **Unit tests:** feed `HingeSample` values with explicit timestamps into `FoldGestureRecognizer` and assert on the returned events. Never use real time or sleeps.
- **Previews and other simulators:** add `.hingeSimulator()` at the root. While it is on, the real hinge is ignored, so it also works on a real iPhone Duo. Its Flick button replays a page turn with exact timing.
- **iPhone Duo simulator (iOS 27.1 runtime):** Device Hub has Closed, Partially Open and Open buttons; hold Option for an angle slider. Turn the simulator panel off to test the real hinge path.

## Common mistakes

- Calling `onHingeChange` directly and comparing raw angles to detect gestures. Use `onFoldEvent`; it handles hysteresis, drift and timing.
- Shipping `.hingeSimulator()` in release builds. Always wrap it in `#if DEBUG`.
- Expecting `pageTurn` from a status-only source. Page turns need the angle; `opened` and `closed` work with status alone.
- Treating `.postureChanged` as `.opened`. A device going from `.noHinge` to `.halfOpen` on first launch is not an opening.
- Putting fold state in `@State` of a view that gets recreated per page. Attach `onFoldEvent` to a stable parent view.
