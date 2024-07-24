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
            name: "WireSystemPackage",
            type: .dynamic,
            targets: ["WireSystem"]
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
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
