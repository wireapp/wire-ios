// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireLinkPreview",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireLinkPreview", type: .dynamic, targets: ["WireLinkPreview"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/wireapp/HTMLString", exact: "6.0.1")
    ],
    targets: [
        .target(
            name: "WireLinkPreview",
            dependencies: ["HTMLString"],
            path: "./Sources/WireLinkPreview",
            swiftSettings: swiftSettings
        ),
        .testTarget(name: "WireLinkPreviewTests", dependencies: ["WireLinkPreview"], path: "./Tests/WireLinkPreviewTests")
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
