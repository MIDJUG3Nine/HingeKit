# HingeKit

[English](README.md) | 简体中文

<p align="center">
  <a href="https://github.com/MIDJUG3Nine/HingeKit/actions/workflows/ci.yml"><img src="https://github.com/MIDJUG3Nine/HingeKit/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white" alt="Swift 6.0+"></a>
  <a href="#环境要求"><img src="https://img.shields.io/badge/platforms-iOS%2017%2B%20%C2%B7%20macOS%2014%2B-000000?logo=apple&logoColor=white" alt="Platforms: iOS 17+ · macOS 14+"></a>
  <a href="https://github.com/MIDJUG3Nine/HingeKit/stargazers"><img src="https://img.shields.io/github/stars/MIDJUG3Nine/HingeKit?style=flat" alt="GitHub stars"></a>
</p>

<p align="center">
  <a href="https://midjug3nine.github.io/HingeKit/">在线演示</a> · <a href="docs/how-it-works.zh-CN.md">原理</a> · <a href="skills/hingekit/SKILL.md">Agent skill</a>
</p>

**在 SwiftUI 里把 iPhone Duo 的铰链当作输入。** 像翻书一样打开手机、合上，或者快速半合再打开来翻一页，每个动作都会得到一个干净的事件。

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

## 为什么用 HingeKit

iOS 27.1 只给你最原始的铰链数据：`onHingeChange` 会在手机开合时报告一个状态和一个角度。用它画个量角器够了，但要判断用户是刚把书打开、合上，还是快速半合一下想翻页，还远远不够，每个 App 都得自己写阈值、去抖和计时。

HingeKit 把这部分做好了。它把原始数据流整理成 App 可以直接 `switch` 的手势（`opened`、`closed`、`pageTurn`）和姿态（`closed`、`halfOpen`、`flat`、`noHinge`）；配套的铰链模拟面板让你在 Xcode 预览或任意模拟器里就能开发和测试，不用先买一台 1999 美元的手机。

## 功能

- **折叠手势。** `opened`、`closed` 和 `pageTurn`（快速半合再打开），阈值可调。
- **带滞后的姿态识别。** `closed`、`halfOpen`、`flat` 和 `noHinge`；铰链停在阈值附近时也不会来回跳。
- **铰链模拟面板。** `.hingeSimulator()` 用一个滑块和 Close / Flick / Flat 按钮模拟铰链，在 Xcode 预览、任意模拟器和任何手机上都能用。iPhone Duo 模拟器自带铰链按钮，但这个面板在预览和没有铰链的设备上也能用，而且 Flick 按钮能按精确的时间重放一次翻页动作，这一点手动很难做到。
- **哪里都能跑。** 在没有铰链的 iPhone 和 iPad 上，姿态是 `.noHinge`，不会触发任何事件，一套代码覆盖所有设备。
- **纯值类型、有测试的核心。** `FoldGestureRecognizer` 和 `PostureClassifier` 是值类型，没有计时器，也不调用系统接口：喂进采样，拿回事件。

## 环境要求

- 读取真实铰链需要 Xcode 27.1 或更高版本（Swift 6.4）。包声明的最低版本是 iOS 17，所以同一份代码也能在旧设备上运行，只是那里没有铰链。
- iPhone Duo 模拟器需要 iOS 27.1 模拟器运行时（Xcode → Settings → Components）。它的 Device Hub 里有 Closed、Partially Open 和 Open 按钮，按住 Option 会出现一个滑块，可以折到任意角度。

## 安装

使用 Swift Package Manager：

```swift
.package(url: "https://github.com/MIDJUG3Nine/HingeKit.git", from: "0.1.0")
```

## 用法

### 响应折叠手势

```swift
.onFoldEvent { event in
    if event == .pageTurn { page += 1 }
}
```

### 根据姿态布局

```swift
FoldReader { fold in
    switch fold.posture {
    case .halfOpen: LaptopLayout()      // content on top, controls below
    case .flat:     TwoColumnLayout()
    case .closed, .noHinge: CompactLayout()
    }
}
```

系统报告了角度时，`fold.angle` 给出打开的角度（单位为度，0 是合上，180 是展平）。

### 开发时模拟铰链

```swift
ContentView()
    #if DEBUG
    .hingeSimulator()
    #endif
```

面板打开时 HingeKit 会忽略真实铰链，所以在真机 iPhone Duo 上也能用这个面板。

### 不用 SwiftUI，直接用核心

```swift
var recognizer = FoldGestureRecognizer()
let events = recognizer.process(HingeSample(status: .partiallyOpen, angle: 120, timestamp: now))
```

翻页手势可以通过 `FoldGestureRecognizer.Configuration` 调整（下压深度以度为单位，时间窗口以秒为单位）。

## 翻页是怎么判断的

设备打开时，HingeKit 会持续跟踪一个「静止角度」。如果角度比它低了至少 25°，并且在一秒内回到距它 10° 以内，就算一次翻页。慢慢地折、轻微晃动、压下去没有回来，都会被忽略。`Tests/HingeKitTests` 里的测试覆盖了每一种情况。

## Agent skill

[`skills/hingekit`](skills/hingekit/SKILL.md) 告诉编程助手怎么用 HingeKit：安装、各个 API、模拟面板和常见错误。把 `skills/hingekit` 文件夹复制到你项目的 `.claude/skills/` 文件夹（Claude Code），或者你所用编程助手的 skills 文件夹里，助手在做铰链相关功能时就会用上它。

## 示例 App

[Answer Book](https://github.com/MIDJUG3Nine/AnswerBook_iDUO) 是一个基于 HingeKit 的小型开源 App：合上手机是书的封面，打开就随机翻到写着答案的一页。

## 相关项目

- [iPhone-Duo-by-Examples](https://github.com/artemnovichkov/iPhone-Duo-by-Examples)：iPhone Duo 各个 API 的 SwiftUI 示例，包括几个铰链小玩具。
- [DuoKit](https://github.com/arjunkshah12345-hash/duokit)：面向 SwiftUI 和 Web 的折叠感知分栏布局。
- [iphone-duo-simulator](https://github.com/acc-ai-tech/iphone-duo-simulator)：在 iPad 模拟器里预览 iPhone Duo 的屏幕尺寸和姿态。

HingeKit 专注于把铰链当作输入设备，体量很小，可以和上面任何一个搭配使用。

## 路线图

- UIKit 支持，基于 `UIHingeInteraction`。
- 一个连续的 `foldProgress` 值（0 为合上，1 为展平），方便用角度驱动动画。
- 更多手势：保持半开、连续两次快速翻页（double flick）。
- DocC 文档。

欢迎在 Issues 里提想法或发 PR。

## 当前状态

v0.1 还很早期。阈值目前是用模拟输入调出来的，非常欢迎用真机试过后在 Issues 里反馈。

HingeKit 是独立项目，与 Apple 无关。iPhone 是 Apple Inc. 的商标。

## 许可

MIT。
