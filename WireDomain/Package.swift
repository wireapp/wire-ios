// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPkg"]),
        .library(name: "WireDomainPackageSupport", targets: ["WireDomainPkgSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireAPI"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins"),
    ],
    targets: [
        .target(
            name: "WireDomainPkg",
            dependencies: [
                "WireAPI",
                "WireLogging",
                .product(name: "WireFoundation", package: "WireFoundation")
            ]
        ),
        .target(
            name: "WireDomainPkgSupport",
            dependencies: ["WireDomainPkg"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireDomainPkgTests",
            dependencies: [
                "WireDomainPkg",
                "WireDomainPkgSupport",
                .product(name: "WireFoundationSupport", package: "WireFoundation")
            ]
        ),
    ]
)

for target in package.targets where target.type != .binary {
    target.swiftSettings = [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
