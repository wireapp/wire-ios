// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        // TODO: [WPB-7394] `Clibsodium` is no longer needed as a product
        .library(name: "Clibsodium", targets: ["Clibsodium"]),
        .library(name: "WireCrypto", targets: ["WireCrypto"]),
        .library(name: "WireFoundation", targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", targets: ["WireFoundationSupport"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .binaryTarget(
            name: "Clibsodium",
            url: "https://github.com/wireapp/libsodium/releases/download/1.0.14/Clibsodium.xcframework.zip",
            checksum: "837bd861aa034f0bf0000bad55d030beab03369baeda11ef9e4c3672b0d7459f"
        ),

        .target(
            name: "WireCrypto",
            dependencies: ["Clibsodium"]
        ),
        .testTarget(
            name: "WireCryptoTests",
            dependencies: ["WireCrypto", "WireTestingPackage"]
        ),

        .target(name: "WireFoundation"),
        .testTarget(
            name: "WireFoundationTests",
            dependencies: ["WireFoundation", "WireFoundationSupport", "WireTestingPackage"]
        ),
        .target(
            name: "WireFoundationSupport",
            dependencies: ["WireFoundation"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),

        .target(
            name: "WireTestingPackage",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "./Sources/WireTesting"
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where target.name != "Clibsodium" {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
