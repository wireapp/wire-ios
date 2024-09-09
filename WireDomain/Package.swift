// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPkg"]),
        .library(name: "WireDomainPackageSupport", targets: ["WireDomainPkgSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../SourceryPlugin"),
        .package(name: "WireAPI", path: "../WireAPI")
    ],
    targets: [
        .target(name: "WireDomainPkg", dependencies: ["WireAPI"], path: "./Sources/Package"),
        .testTarget(name: "WireDomainPkgTests", dependencies: ["WireDomainPkg"], path: "./Tests/PackageTests"),

        .target(
            name: "WireDomainPkgSupport",
            dependencies: ["WireDomainPkg"],
            path: "./Sources/PackageSupport",
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
