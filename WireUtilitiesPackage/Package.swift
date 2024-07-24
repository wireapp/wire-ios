// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUtilitiesPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "WireUtilitiesPackage",
            type: .dynamic,
            targets: ["WireUtilitiesPackage"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "WireUtilitiesPackage",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WireUtilitiesPackageTests",
            dependencies: [
                "WireUtilitiesPackage"
            ]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
