// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireFoundation", targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", targets: ["WireFoundationSupport"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(name: "WireFoundation", dependencies: ["CocoaLumberjack"]),
        .testTarget(name: "WireFoundationTests", dependencies: ["WireFoundation", "WireFoundationSupport", "WireTestingPackage"]),
        .target(
            name: "WireFoundationSupport",
            dependencies: ["WireFoundation"],
            plugins: [.plugin(name: "SourceryPlugin", package: "SourceryPlugin")]
        ),
        .target(
            name: "WireTestingPackage",
            dependencies: [
                "WireFoundation",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "./Sources/WireTesting"
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
