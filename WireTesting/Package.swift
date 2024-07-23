// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireTesting",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WireTesting",
            targets: ["WireTesting"]
        ),
        .library(
            name: "WireTestingObjectiveC",
            targets: ["WireTestingObjectiveC"]
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
            name: "WireTesting",
            dependencies: [
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                )
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireTestingTests",
            dependencies: [
                "WireTesting"
            ]
        ),

        .target(
            name: "WireTestingObjectiveC",
            dependencies: [
                .product(
                    name: "SnapshotTesting",
                    package: "swift-snapshot-testing"
                )
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireTestingObjectiveCTests",
            dependencies: [
                "WireTestingObjectiveC"
            ]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
