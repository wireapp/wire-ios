// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage",type: .dynamic, targets: ["WireDomainPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.16.0"),
        .package(path: "../SourceryPlugin"),
        .package(path: "../WireSystemPackage")
    ],
    targets: [
        .target(
            name: "WireDomainPackage",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                "WireSystemPackage"
            ],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        ),
        .testTarget(
            name: "WireDomainPackageTests",
            dependencies: ["WireDomainPackage"]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
