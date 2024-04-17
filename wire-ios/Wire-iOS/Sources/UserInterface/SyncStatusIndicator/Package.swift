// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SyncStatusIndicator",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "SyncStatusIndicator",
            targets: ["SyncStatusIndicator"])
    ],
    targets: [
        .target(
            name: "SyncStatusIndicator"),
        .testTarget(
            name: "SyncStatusIndicatorTests",
            dependencies: ["SyncStatusIndicator"])
    ]
)
