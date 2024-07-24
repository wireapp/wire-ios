// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireSystemPackage",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WireSystemPackage",
            type: .dynamic,
            targets: ["WireSystemPackage"]
        )
    ],
    targets: [
        .target(
            name: "WireSystemPackage",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireSystemPackageTests",
            dependencies: [
                "WireSystemPackage"
            ]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
