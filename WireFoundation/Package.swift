// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireFoundation", targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", targets: ["WireFoundationSupport"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"]),
        .plugin(name: "SnapshotTestReferenceDirectoryPlugin", targets: ["SnapshotTestReferenceDirectoryPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(name: "WireFoundation"),
        .testTarget(
            name: "WireFoundationTests",
            dependencies: ["WireFoundation", "WireFoundationSupport", "WireTestingPackage"],
            plugins: ["SnapshotTestReferenceDirectoryPlugin"]
        ),
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
        ),
        .plugin(name: "SnapshotTestReferenceDirectoryPlugin", capability: .buildTool())
    ]
)

for target in package.targets {
    guard target.type != .plugin else { continue }
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
