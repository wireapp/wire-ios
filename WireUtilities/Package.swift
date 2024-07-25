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
        .package(name: "WireSystemPackage", path: "../WireSystem")
    ],
    targets: [
        .target(name: "WireUtilities", dependencies: ["WireSystemPackage"], path: "./Sources/WireUtilities", swiftSettings: swiftSettings),
        .testTarget(name: "WireUtilitiesTests", dependencies: ["WireUtilities"], path: "./Tests/WireUtilitiesTests", swiftSettings: swiftSettings),

        .target(
            name: "WireUtilitiesSupport",
            dependencies: ["WireUtilities"],
            path: "./Sources/WireUtilitiesSupport",
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
