// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireTestingNew",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // TODO: [WPB-8907]: Rename this to WireTesting and migrate everything from the WireTesting project
        .library(
            name: "WireTestingNew",
            targets: ["WireTestingNew"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.1.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.16.0"
        )
    ],
    targets: [
        .target(
            name: "WireTestingNew",
            dependencies: [
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                )
            ],
            path: "./Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireTestingNewTests",
            path: "./Tests"
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
