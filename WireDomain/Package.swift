// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPackage"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireAPI"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
    ],
    targets: [
        .target(
            name: "WireDomainPackage",
            dependencies: [
                "WireAPI",
                "WireLogging",
                .product(name: "WireFoundation", package: "WireFoundation")
            ]
        )
    ]
)

for target in package.targets where target.type != .binary {
    target.swiftSettings = [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
