// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"]),
        .library(name: "WireUIBase", targets: ["WireUIBase"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
        .package(name: "WireSystemPackage", path: "../WireSystem"),
        .package(name: "WireUtilitiesPackage", path: "../WireUtilities"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(name: "WireDesign"),
        .testTarget(
            name: "WireDesignTests",
            dependencies: ["WireDesign", .product(name: "SnapshotTesting", package: "swift-snapshot-testing")]
        ),

        .target(
            name: "WireReusableUIComponents",
            dependencies: [
                "WireDesign",
                "WireSystemPackage",
                "WireUtilitiesPackage",
                .product(name: "WireTestingPackage", package: "WireFoundation")
            ]),
        .testTarget(
            name: "WireReusableUIComponentsTests",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                "WireReusableUIComponents",
                .product(name: "WireTestingPackage", package: "WireFoundation")
            ]
        ),

        .target(name: "WireUIBase", dependencies: ["WireDesign"]),
        .testTarget(
            name: "WireUIBaseTests",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                "WireUIBase",
                .product(name: "WireTestingPackage", package: "WireFoundation")
            ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
