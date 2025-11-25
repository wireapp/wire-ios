// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireFoundation",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        // TODO: [WPB-7394] `Clibsodium` is no longer needed as a product
        .library(name: "Clibsodium", targets: ["Clibsodium"]),
        .library(name: "WireCrypto", targets: ["WireCrypto"]),
        .library(name: "WireFoundation", targets: ["WireFoundation"]),
        .library(name: "WireFoundationSupport", targets: ["WireFoundationSupport"]),
        .library(name: "WireTestingPackage", targets: ["WireTestingPackage"]),
        .library(name: "WireUtilitiesPackage", targets: ["WireUtilitiesPackage"]),
        .library(name: "WireUtilitiesPackageSupport", targets: ["WireUtilitiesPackageSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.3"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
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
            dependencies: [
                "WireFoundation",
                "WireFoundationSupport",
                "WireTestingPackage"
            ]
        ),
        .target(
            name: "WireFoundationSupport",
            dependencies: ["WireFoundation"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),

        .target(
            name: "WireUtilitiesPackage",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ]
        ),
        .testTarget(
            name: "WireUtilitiesPackageTests",
            dependencies: [
                "WireUtilitiesPackage",
                "WireUtilitiesPackageSupport"
            ],
            resources: [
                .copy("Resources/single-file.zip"),
                .copy("Resources/single-file-in-directory.zip")
            ]
        ),
        .target(
            name: "WireUtilitiesPackageSupport",
            dependencies: ["WireUtilitiesPackage"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
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
