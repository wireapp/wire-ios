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
            url: "https://media.githubusercontent.com/media/wireapp/wire-ios/cff4f8227ece376dd78a4f30af8ff781bfb8d16a/WireDomain/Frameworks/WireBackup.xcframework.zip?download=true",
            checksum: "d840221eada972dac752f3e652495ea7e23159dde538bfe7a39e8e7c5b149810"
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
