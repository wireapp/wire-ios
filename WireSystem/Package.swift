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
    dependencies: [
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", .upToNextMajor(from: "3.8.5"))
    ],
    targets: [
        .target(
            name: "WireSystem",
            dependencies: [
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                "ZipArchive"
            ],
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
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireSystemObjectiveCTests",
            dependencies: [
                "WireSystem",
                "WireSystemObjectiveC"
            ]
        ),

        .binaryTarget(
            name: "ZipArchive",
            path: "../Carthage/Build/ZipArchive.xcframework"
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
