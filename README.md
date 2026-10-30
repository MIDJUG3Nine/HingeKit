# HingeKit

**Use the iPhone Duo hinge as input in SwiftUI.** Open the phone like a book, close it, or flick it half shut to turn a page, and get a clean event for each.

```swift
import HingeKit

BookView()
    .onFoldEvent { event in
        switch event {
        case .opened:   showRandomPage()
        case .pageTurn: showNextPage()
        case .closed:   showCover()
        case .postureChanged: break
        }
    }
```

iOS 27.1 gives you the raw hinge (`onHingeChange`, with a status and an angle). HingeKit turns that stream into things an app can act on, and lets you build all of it without owning a $1,999 phone.

## Features

- **Fold gestures.** `opened`, `closed` and `pageTurn` (a quick partial fold and back), with thresholds you can tune.
- **Postures with hysteresis.** `closed`, `halfOpen`, `flat` and `noHinge`, without flicker when the hinge rests near a threshold.
- **Hinge simulator panel.** `.hingeSimulator()` fakes the hinge with a slider and Close / Flick / Flat buttons, in Xcode Previews, in any simulator and on any phone. The iOS 27.1 Simulator has no hinge control, so this is the easiest way to test fold logic today.
- **Works everywhere.** On phones and iPads without a hinge, the posture is `.noHinge` and no events fire, so one code path covers every device.
- **Pure, tested core.** `FoldGestureRecognizer` and `PostureClassifier` are value types with no timers or system calls. Feed them samples, get events back.

## Requirements

- Xcode 27.1 or later (Swift 6.4) to read the real hinge. The package declares iOS 17 so the same code runs on older devices, where the hinge is simply absent.
- The iPhone Duo simulator needs the iOS 27.1 simulator runtime (Xcode → Settings → Components).

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/MIDJUG3Nine/HingeKit.git", from: "0.1.0")
```

## Usage

### React to fold gestures

```swift
.onFoldEvent { event in
    if event == .pageTurn { page += 1 }
}
```

### Lay out against the posture

```swift
FoldReader { fold in
    switch fold.posture {
    case .halfOpen: LaptopLayout()      // content on top, controls below
    case .flat:     TwoColumnLayout()
    case .closed, .noHinge: CompactLayout()
    }
}
```

`fold.angle` gives the opening angle in degrees (0 closed, 180 flat) when the system reports one.

### Fake the hinge while you build

```swift
ContentView()
    #if DEBUG
    .hingeSimulator()
    #endif
```

While the panel is on, HingeKit ignores the real hinge, so the panel works on a real iPhone Duo too.

### Use the core without SwiftUI

```swift
var recognizer = FoldGestureRecognizer()
let events = recognizer.process(HingeSample(status: .partiallyOpen, angle: 120, timestamp: now))
```

Tune the page-turn gesture through `FoldGestureRecognizer.Configuration` (depth in degrees, time window in seconds).

## How the page turn works

While the device is open, HingeKit tracks a resting angle. A page turn is a dip of at least 25° below it that comes back within 10° in under a second. Slow folds, small wobbles and dips that never come back are ignored. The tests in `Tests/HingeKitTests` cover each case.

## Example app

[Answer Book](https://github.com/MIDJUG3Nine/AnswerBook_iDUO) is a small open-source app built on HingeKit: close the phone and it is a book cover, open it and you land on a random page with an answer.

## Related projects

- [iPhone-Duo-by-Examples](https://github.com/artemnovichkov/iPhone-Duo-by-Examples): SwiftUI examples of the iPhone Duo APIs, including hinge toys.
- [DuoKit](https://github.com/arjunkshah12345-hash/duokit): fold-aware split layouts for SwiftUI and the web.
- [iphone-duo-simulator](https://github.com/acc-ai-tech/iphone-duo-simulator): previews iPhone Duo screen sizes and postures inside the iPad simulator.

HingeKit focuses on the hinge as an input device and stays small enough to combine with any of them.

## Status

v0.1 is early. The thresholds were tuned against simulated input; real-device feedback is very welcome in the issues.

HingeKit is an independent project and is not affiliated with Apple. iPhone is a trademark of Apple Inc.

## License

MIT.
