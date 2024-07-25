// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireSystemPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireSystemPackage", type: .dynamic, targets: ["WireSystemPkg"]),
        .library(name: "WireSystemPackageSupport", type: .dynamic, targets: ["WireSystemPkgSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin")
    ],
    targets: [
        .target(name: "WireSystemPkg", path: "./Sources/WireSystem", swiftSettings: swiftSettings),
        .testTarget(name: "WireSystemPkgTests", dependencies: ["WireSystemPkg"], path: "./Tests/WireSystemTests"),

        .target(
            name: "WireSystemPkgSupport",
            dependencies: ["WireSystemPkg"],
            path: "./Sources/WireSystemSupport",
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
