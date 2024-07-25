// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUtilitiesPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireUtilitiesPackage", type: .dynamic, targets: ["WireUtilities"]),
        .library(name: "WireUtilitiesPackageSupport", type: .dynamic, targets: ["WireUtilitiesSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin"),
        .package(path: "../WireSystemPackage")
    ],
    targets: [
        .target(name: "WireUtilities", dependencies: ["WireSystemPackage"], path: "./Sources/WireUtilitiesPackage", swiftSettings: swiftSettings),
        .testTarget(name: "WireUtilitiesTests", dependencies: ["WireUtilities"], path: "./Tests/WireUtilitiesPackageTests", swiftSettings: swiftSettings),

        .target(
            name: "WireUtilitiesSupport",
            dependencies: ["WireUtilities"],
            path: "./Sources/WireUtilitiesPackageSupport",
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
