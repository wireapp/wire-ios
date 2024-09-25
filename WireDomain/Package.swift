// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", type: .dynamic, targets: ["WireDomainPkg"]),
        .library(name: "WireDomainPackageSupport", type: .dynamic, targets: ["WireDomainPkgSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin"),
        .package(name: "WireAPI", path: "../WireAPI")
    ],
    targets: [
        .target(name: "WireDomainPkg", dependencies: ["WireAPI"], path: "./Sources/Package", swiftSettings: swiftSettings),
        .testTarget(name: "WireDomainPkgTests", dependencies: ["WireDomainPkg"], path: "./Tests/PackageTests"),

        .target(
            name: "WireDomainPkgSupport",
            dependencies: ["WireDomainPkg"],
            path: "./Sources/PackageSupport",
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
