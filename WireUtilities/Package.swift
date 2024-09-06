// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUtilitiesPackage",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireUtilitiesPackage", type: .dynamic, targets: ["WireUtilitiesPkg"]),
        .library(name: "WireUtilitiesPackageSupport", type: .dynamic, targets: ["WireUtilitiesPkgSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin"),
        .package(name: "WireSystemPackage", path: "../WireSystem")
    ],
    targets: [
        .target(name: "WireUtilitiesPkg", dependencies: ["WireSystemPackage"], path: "./Sources/WireUtilities"),
        .testTarget(name: "WireUtilitiesPkgTests", dependencies: ["WireUtilitiesPkg"], path: "./Tests/WireUtilitiesTests"),

        .target(
            name: "WireUtilitiesPkgSupport",
            dependencies: ["WireUtilitiesPkg"],
            path: "./Sources/WireUtilitiesSupport",
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
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
