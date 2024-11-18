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
        .library(name: "WireSystemSupportPackage", targets: ["WireSystemSupportPackage"]),
        .library(name: "WireUtilitiesPackage", targets: ["WireUtilitiesPackage"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(name: "WireFoundation"),
        .target(
            name: "WireFoundationSupport",
            dependencies: ["WireFoundation"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireFoundationTests",
            dependencies: ["WireFoundation", "WireFoundationSupport", "WireTestingPackage"]
        ),

            .target(
                name: "WireSystemPackage",
                path: "./Sources/WireSystem"
            ),
        .target(
            name: "WireSystemSupportPackage",
            dependencies: ["WireSystemPackage"],
            path: "./Sources/WireSystemSupport",
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
            .testTarget(
                name: "WireSystemPackageTests",
                dependencies: ["WireSystemPackage", "WireSystemSupportPackage"],
                path: "./Tests/WireSystemTests"
            ),

        .target(
            name: "WireTestingPackage",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "./Sources/WireTesting"
        ),

            .target(
                name: "WireUtilitiesPackage",
                path: "./Sources/WireUtilities"
            ),
            .testTarget(
                name: "WireUtilitiesPackageTests",
                dependencies: ["WireUtilitiesPackage"],
                path: "./Tests/WireUtilitiesTests"
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
