// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireTestingPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireTestingPackage", type: .dynamic, targets: ["WireTestingPkg"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.16.0"),
        .package(name: "WireSystemPackage", path: "../WireSystem")
    ],
    targets: [
        .target(
            name: "WireTestingPkg",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "WireSystemPackageSupport", package: "WireSystemPackage")
            ],
            path: "./Sources/WireTesting",
            swiftSettings: swiftSettings
        ),
        .testTarget(name: "WireTestingPkgTests", dependencies: ["WireTestingPkg"], path: "./Tests/WireTestingTests")
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
