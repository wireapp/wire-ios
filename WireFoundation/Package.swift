// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireFoundation", type: .dynamic, targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", type: .dynamic, targets: ["WireFoundationSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(name: "WireFoundation", path: "./Sources/WireFoundation", swiftSettings: swiftSettings),
        .testTarget(name: "WireFoundationTests", dependencies: ["WireFoundation"], path: "./Tests/WireFoundationTests"),

        .target(
            name: "WireFoundationSupport",
            dependencies: ["WireFoundation"],
            path: "./Sources/WireFoundationSupport",
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
