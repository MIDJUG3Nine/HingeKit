// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HingeKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "HingeKit", targets: ["HingeKit"]),
    ],
    targets: [
        .target(name: "HingeKit"),
        .testTarget(name: "HingeKitTests", dependencies: ["HingeKit"]),
    ]
)
