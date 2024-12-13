// swift-tools-version: 6.0

import Foundation
import PackageDescription

let isDisabled = ProcessInfo.processInfo.environment["EXCLUDE_DEVELOPER_TOOLS"] == "1"

let package = Package(
    name: "WireDeveloperTools",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireDeveloperTools", targets: ["WireDeveloperTools"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
    ],
    swiftLanguageModes: [.v6]
)

if !isDisabled {
    package.targets += [
        .target(name: "WireDeveloperTools"),
        .testTarget(name: "WireDeveloperToolsTests", dependencies: ["WireDeveloperTools"]),
        // TODO: add more targets
    ]
} else {
    package.targets += [
        .target(
            name: "WireDeveloperTools",
            sources: ["./WireDeveloperPlaceholder.swift"]
        )
    ]
}

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("FullTypedThrows"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
