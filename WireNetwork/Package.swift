// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WireNetwork",
    platforms: [.iOS(.v17), .macOS(.v12)],
    products: [
        .library(name: "WireNetwork", type: .dynamic, targets: ["WireNetwork"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireLogging"),
        .package(path: "../WireFoundation")
    ],
    targets: [
        .target(
            name: "WireNetwork",
            dependencies: [
                .product(name: "WireFoundation", package: "WireFoundation"),
                .product(name: "WireLogging", package: "WireLogging"),
                .product(name: "WireCrypto", package: "WireFoundation")
            ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
