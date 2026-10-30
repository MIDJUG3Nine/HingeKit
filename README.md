# HingeKit

English | [简体中文](README.zh-CN.md)

<p align="center">
  <a href="https://github.com/MIDJUG3Nine/HingeKit/actions/workflows/ci.yml"><img src="https://github.com/MIDJUG3Nine/HingeKit/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white" alt="Swift 6.0+"></a>
  <a href="#requirements"><img src="https://img.shields.io/badge/platforms-iOS%2017%2B%20%C2%B7%20macOS%2014%2B-000000?logo=apple&logoColor=white" alt="Platforms: iOS 17+ · macOS 14+"></a>
  <a href="https://github.com/MIDJUG3Nine/HingeKit/stargazers"><img src="https://img.shields.io/github/stars/MIDJUG3Nine/HingeKit?style=flat" alt="GitHub stars"></a>
</p>

<p align="center">
  <a href="https://midjug3nine.github.io/HingeKit/">Live demo</a> · <a href="docs/how-it-works.md">How it works</a> · <a href="skills/hingekit/SKILL.md">Agent skill</a>
</p>

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

<!-- demo gif -->

## Why HingeKit

iOS 27.1 gives you the raw hinge: `onHingeChange` reports a status and an angle as the phone folds. That is enough to draw a protractor, but not to tell whether someone just opened the book, closed it, or flicked it half shut to turn a page. Each app would have to write its own thresholds, smoothing and timing.

HingeKit does that part once. It turns the raw stream into gestures (`opened`, `closed`, `pageTurn`) and postures (`closed`, `halfOpen`, `flat`, `noHinge`) that an app can switch on, and its hinge simulator lets you build and test all of it in Xcode Previews or any simulator, without owning a $1,999 phone.

## Features

- **Fold gestures.** `opened`, `closed` and `pageTurn` (a quick partial fold and back), with thresholds you can tune.
- **Postures with hysteresis.** `closed`, `halfOpen`, `flat` and `noHinge`, without flicker when the hinge rests near a threshold.
- **Hinge simulator panel.** `.hingeSimulator()` fakes the hinge with a slider and Close / Flick / Flat buttons, in Xcode Previews, in any simulator and on any phone. The iPhone Duo simulator has hinge buttons of its own, but the panel also works in Previews and on devices without a hinge, and its Flick button replays a quick page-turn fold with exact timing, which is hard to do by hand.
- **Works everywhere.** On phones and iPads without a hinge, the posture is `.noHinge` and no events fire, so one code path covers every device.
- **Pure, tested core.** `FoldGestureRecognizer` and `PostureClassifier` are value types with no timers or system calls. Feed them samples, get events back.

## Requirements

- Xcode 27.1 or later (Swift 6.4) to read the real hinge. The package declares iOS 17 so the same code runs on older devices, where the hinge is simply absent.
- The iPhone Duo simulator needs the iOS 27.1 simulator runtime (Xcode → Settings → Components). Its Device Hub has Closed, Partially Open and Open buttons, and holding Option shows a slider for any fold angle.

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

## Agent skill

[`skills/hingekit`](skills/hingekit/SKILL.md) teaches a coding agent how to use HingeKit: installing it, the APIs, the simulator panel and common mistakes. Copy the `skills/hingekit` folder into your project's `.claude/skills/` folder (Claude Code) or your coding agent's skills folder, and the agent will pick it up when you work on hinge features.

## Example app

[Answer Book](https://github.com/MIDJUG3Nine/AnswerBook_iDUO) is a small open-source app built on HingeKit: close the phone and it is a book cover, open it and you land on a random page with an answer.

## Related projects

- [iPhone-Duo-by-Examples](https://github.com/artemnovichkov/iPhone-Duo-by-Examples): SwiftUI examples of the iPhone Duo APIs, including hinge toys.
- [DuoKit](https://github.com/arjunkshah12345-hash/duokit): fold-aware split layouts for SwiftUI and the web.
- [iphone-duo-simulator](https://github.com/acc-ai-tech/iphone-duo-simulator): previews iPhone Duo screen sizes and postures inside the iPad simulator.

HingeKit focuses on the hinge as an input device and stays small enough to combine with any of them.

## Roadmap

- UIKit support, built on `UIHingeInteraction`.
- A continuous `foldProgress` value (0 closed, 1 flat) for driving animations from the angle.
- More gestures: hold half-open, double flick.
- DocC documentation.

Ideas and pull requests are welcome in the issues.

## Status

v0.1 is early. The thresholds were tuned against simulated input; real-device feedback is very welcome in the issues.

HingeKit is an independent project and is not affiliated with Apple. iPhone is a trademark of Apple Inc.

## License

MIT.
