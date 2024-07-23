// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireSystem",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WireSystem",
            targets: ["WireSystem"]
        ),
        .library(
            name: "WireSystemObjectiveC",
            targets: ["WireSystemObjectiveC"]
        )
    ],
    targets: [
        .target(
            name: "WireSystem",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireSystemTests",
            dependencies: [
                "WireSystem"
            ]
        ),

        .target(
            name: "WireSystemObjectiveC",
            dependencies: ["WireSystem"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireSystemObjectiveCTests",
            dependencies: [
                "WireSystemObjectiveC"
            ]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
