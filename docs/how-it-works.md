# How the page turn works

English | [简体中文](how-it-works.zh-CN.md)

iOS 27.1 reports the iPhone Duo hinge as a status (closed, partially open, fully open) and an angle from 0° to 180°. HingeKit turns that stream into three things an app cares about: a **posture**, an **opened / closed** event, and a **page turn**.

You can try all of it in the [live demo](https://midjug3nine.github.io/HingeKit/).

![Two charts of hinge angle over time. A quick dip is a page turn; a slow fold is not.](images/page-turn.svg)

## 1. Posture, with hysteresis

`PostureClassifier` maps each sample to `closed`, `halfOpen` or `flat`:

| Angle | Posture |
| --- | --- |
| status is closed, or angle ≤ 8° | `closed` |
| between | `halfOpen` |
| ≥ 165° | `flat` |

A hinge resting right at 165° would flicker between `halfOpen` and `flat`. To stop that, leaving a posture needs an extra 10°: a flat device stays `flat` until the angle drops below 155°, and a closed device stays `closed` until it passes 18°.

## 2. Opened and closed

`FoldGestureRecognizer` compares each posture with the previous one. `closed` → `halfOpen` or `flat` is `.opened`. `halfOpen` or `flat` → `closed` is `.closed`. Every change is also reported as `.postureChanged(from:to:)`.

These work even when the system only reports a status and no angle.

## 3. The page turn

While the device is open, the recognizer keeps a **resting angle**: where the user is holding the hinge.

1. If the angle rises, the resting angle follows it at once. If it drifts down a little, the resting angle follows slowly (20% per sample), so small wobbles are absorbed.
2. When the angle falls **8° or more** below the resting angle, a dip starts and the clock starts.
3. The dip becomes a `.pageTurn` when it has gone **at least 25° deep** and the hinge has come back to **within 10°** of the resting angle.
4. If that hasn't happened **within 1 second**, it wasn't a flick. The dip is dropped and the resting angle moves to the new angle, so a slow fold to a new position never turns a page.

Closing the device resets everything. Opening it sets the resting angle to the first open angle.

All five numbers live in `FoldGestureRecognizer.Configuration`:

```swift
var config = FoldGestureRecognizer.Configuration()
config.pageTurnDepth = 30      // degrees
config.pageTurnWindow = 0.8    // seconds
let recognizer = FoldGestureRecognizer(configuration: config)
```

## Why it's built this way

- **Pure value types.** No timers, no `Date()`, no system calls. Time comes from the samples, so the same code runs on the real hinge, the simulator panel, the web demo and the unit tests.
- **Tested.** Each case above (quick dip, shallow wobble, slow fold, dip that never comes back, two flicks in a row, flick from flat, status-only sources) has a test in [`Tests/HingeKitTests`](../Tests/HingeKitTests).
- **Tuned on simulated input.** The defaults are a starting point. If they feel wrong on a real iPhone Duo, please open an issue with what you tried.
