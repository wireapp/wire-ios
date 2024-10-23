// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPkg"]),
        .library(name: "WireDomainPackageSupport", targets: ["WireDomainPkgSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin"),
        .package(name: "WireAPI", path: "../WireAPI"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(
            name: "WireDomainPkg",
            dependencies: ["WireAPI"],
            path: "./Sources/Package"
        ),
        .target(
            name: "WireDomainPkgSupport",
            dependencies: ["WireDomainPkg"],
            path: "./Sources/PackageSupport",
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        ),
        .testTarget(
            name: "WireDomainPkgTests",
            dependencies: [
                "WireDomainPkg",
                .product(name: "WireTestingPackage", package: "WireFoundation")
            ],
            path: "./Tests/PackageTests"
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
