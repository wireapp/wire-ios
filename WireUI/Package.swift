// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library("WireDesign"),
        .library("WireReusableUIComponents"),
        .library("WireUITesting")
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.16.0"),
        .package(name: "WireSystemPackage", path: "../WireSystem")
    ],
    targets: [

        .target(name: "WireDesign"),
        .testTarget(
            name: "WireDesignTests",
            dependencies: ["WireDesign", .product(name: "SnapshotTesting", package: "swift-snapshot-testing")]
        ),

        .target(name: "WireReusableUIComponents", dependencies: ["WireDesign", "WireSystemPackage"]),
        .testTarget(
            name: "WireReusableUIComponentsTests",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                "WireReusableUIComponents",
                "WireUITesting"
            ]
        ),

        // TODO: [WPB-8907]: Once WireTesting is a Swift package, move everything from here to there.
        .target(
            name: "WireUITesting",
            dependencies: [.product(name: "SnapshotTesting", package: "swift-snapshot-testing")]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny")
    ]
}

extension Product {
    public static func library(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
