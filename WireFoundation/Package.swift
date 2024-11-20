// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireFoundation", targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", targets: ["WireFoundationSupport"]),
        .library(name: "WireSystem", targets: ["WireSystem"]),
        .library(name: "WireSystemSupport", targets: ["WireSystemSupport"]),
        .library(name: "WireUtilitiesPackage", targets: ["WireUtilitiesPackage"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
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
            name: "WireSystem",
            dependencies: [
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                "ZipArchive"
            ]
        ),
        .target(
            name: "WireSystemSupport",
            dependencies: ["WireSystem"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireSystemTests",
            dependencies: ["WireSystem", "WireSystemSupport"]
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
        ),

        .binaryTarget(name: "ZipArchive", path: "../Carthage/Build/ZipArchive.xcframework")
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    guard target.type != .binary else { continue }
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("FullTypedThrows"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
