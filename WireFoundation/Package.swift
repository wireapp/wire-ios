// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireFoundation", targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", targets: ["WireFoundationSupport"]),
        .library(name: "WireSystemPackage", targets: ["WireSystemPackage"]),
        .library(name: "WireSystemPackageSupport", targets: ["WireSystemPackageSupport"]),
        .library(name: "WireUtilitiesPackage", targets: ["WireUtilitiesPackage"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(name: "WireFoundation"),
        .testTarget(
            name: "WireFoundationTests",
            dependencies: ["WireFoundation", "WireFoundationSupport", "WireTestingPackage"]
        ),
        .target(
            name: "WireFoundationSupport",
            dependencies: ["WireFoundation"],
            plugins: [.plugin(name: "SourceryPlugin", package: "SourceryPlugin")]
        ),

        .target(
            name: "WireSystemPackage",
            dependencies: ["ZipArchive"],
            path: "./Sources/WireSystem"
        ),
        .testTarget(
            name: "WireSystemPackageTests",
            dependencies: [
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                "WireSystemPackage",
                "WireSystemPackageSupport",
                "WireTestingPackage"
            ],
            path: "./Tests/WireSystemTests"
        ),
        .target(
            name: "WireSystemPackageSupport",
            dependencies: ["WireSystemPackage"],
            path: "./Sources/WireSystemSupport",
            plugins: [.plugin(name: "SourceryPlugin", package: "SourceryPlugin")]
        ),
        .binaryTarget(name: "ZipArchive", path: "../Carthage/Build/ZipArchive.xcframework"),

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
        )
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
