// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireSystemPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireSystemPackage", type: .dynamic, targets: ["WireSystemPackage"]),
        .library(name: "WireSystemPackageSupport", type: .dynamic, targets: ["WireSystemPackageSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.8.5"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(
            name: "WireSystemPackage",
            dependencies: [
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                "ZipArchive"
            ],
            path: "./Sources/WireSystem",
            swiftSettings: swiftSettings
        ),
        .testTarget(name: "WireSystemPackageTests", dependencies: ["WireSystemPackage"], path: "./Tests/WireSystemTests"),

        .target(
            name: "WireSystemPackageSupport",
            dependencies: ["WireSystemPackage"],
            path: "./Sources/WireSystemSupport",
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        ),

        .binaryTarget(name: "ZipArchive", path: "../Carthage/Build/ZipArchive.xcframework")
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
