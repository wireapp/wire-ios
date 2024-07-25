// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", type: .dynamic, targets: ["WireDomainPackage"]),
        .library(name: "WireDomainPackageSupport", type: .dynamic, targets: ["WireDomainPackageSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin"),
        .package(path: "../WireSystemPackage")
    ],
    targets: [

        .target(name: "WireDomainPackage", swiftSettings: swiftSettings),
        .testTarget(
            name: "WireDomainPackageTests",
            dependencies: ["WireSystemPackage"]
        ),

        .target(
            name: "WireDomainPackageSupport",
            dependencies: ["WireDomainPackage"],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableExperimentalFeature("StrictConcurrency")
]
