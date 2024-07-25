// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireSystemPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireSystemPackage", type: .dynamic, targets: ["WireSystemPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [

        .target(name: "WireSystemPackage", swiftSettings: swiftSettings),
        .testTarget(
            name: "WireSystemPackageTests",
            dependencies: ["WireSystemPackage"]
        ),

        .target(
            name: "WireSystemPackageSupport",
            dependencies: ["WireSystemPackage"],
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
