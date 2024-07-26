// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireSystemPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireSystemPackage", type: .dynamic, targets: ["WireSystemPackage"]),
        .library(name: "WireSystemPackageSupport", type: .dynamic, targets: ["WireSystemPackageSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(name: "WireSystemPackage", path: "./Sources/WireSystem", swiftSettings: swiftSettings),
        .testTarget(name: "WireSystemPackageTests", dependencies: ["WireSystemPackage"], path: "./Tests/WireSystemTests"),

        .target(
            name: "WireSystemPackageSupport",
            dependencies: ["WireSystemPackage"],
            path: "./Sources/WireSystemSupport",
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
