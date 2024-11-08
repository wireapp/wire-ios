// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireFoundation", targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", targets: ["WireFoundationSupport"]),
        .library(name: "WireUtilitiesPackage", targets: ["WireUtilitiesPackage"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"]),
        .plugin(name: "SnapshotTestReferenceDirectoryPlugin", targets: ["SnapshotTestReferenceDirectoryPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
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
            name: "WireUtilitiesPackage",
            path: "./Sources/WireUtilities"
        ),
        .testTarget(
            name: "WireUtilitiesPackageTests",
            dependencies: ["WireUtilitiesPackage"],
            path: "./Tests/WireUtilitiesTests"
        ),

        .target(
            name: "WireTestingPackage",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "./Sources/WireTesting"
        ),

        .plugin(
            name: "SnapshotTestReferenceDirectoryPlugin",
            capability: .buildTool(),
            dependencies: ["swiftgen"]
        ),

        .binaryTarget(
            name: "swiftgen",
            url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.2/swiftgen-6.6.2.artifactbundle.zip",
            checksum: "7586363e24edcf18c2da3ef90f379e9559c1453f48ef5e8fbc0b818fbbc3a045"
        )
    ]
)

for target in package.targets where [.regular, .executable, .test].contains(target.type) {
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
