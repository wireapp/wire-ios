// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPackage"]),
        .library(name: "WireDomainPackageSupport", targets: ["WireDomainPackageSupport"]),
        .library(name: "WireUpdateEventCoding", targets: ["WireUpdateEventCoding"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireNetwork"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireDomainPackage",
            dependencies: [
                "WireNetwork",
                "WireLogging",
                "WireFoundation"
            ]
        ),
        .target(
            name: "WireDomainPackageSupport",
            dependencies: ["WireDomainPackage"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireDomainPackageTests",
            dependencies: [
                "WireDomainPackage",
                "WireDomainPackageSupport",
                .product(name: "WireFoundationSupport", package: "WireFoundation")
            ]
        ),
        .target(
            name: "WireUpdateEventCoding",
            dependencies: ["WireNetwork"]
        ),
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("StrictMemorySafety"),
    ]
}
