// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPkg"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireAPI")
    ],
    targets: [
        .target(
            name: "WireDomainPkg",
            dependencies: [
                "WireAPI",
                "WireBackup"
            ]
        ),
        .binaryTarget(
            name: "WireBackup",
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/2228286f89e83c0dd2a93aab8240e7875fde58ff/WireDomain/Frameworks/WireBackup.xcframework.zip?download=true",
            checksum: "3dce9e475278e9055ee00bfc5674c3a7231939b6b8e44dbfdbc4e7321841478b"
        )
    ]
)

for target in package.targets where target.type != .binary {
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
