// swift-tools-version: 6.0

import PackageDescription

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
    targets: [
        .target(name: "WireDeveloperTools"),
        .testTarget(
            name: "WireDeveloperToolsTests",
            dependencies: ["WireDeveloperTools"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("FullTypedThrows"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
