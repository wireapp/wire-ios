// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPackage"]),
        .library(name: "WireDomainPackageSupport", targets: ["WireDomainPackageSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireAPI"),
        .package(path: "../WireBackup"), // TODO: remove
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireDomainPackage",
            dependencies: [
                "WireAPI",
                "WireBackup",
                "WireLogging",
                "WireFoundation"
            ]
        ),
        .target(
            name: "WireDomainPackageSupport",
            dependencies: ["WireDomainPackage"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
